fs = require 'fs'

tools = require '../tools'
cfg = require '../config'

smtp = require '../smtp'

exports.setUp = (client, db) ->

  mod = {}

  mod.get = (id, fn) ->
    client.smembers "users:#{id}:projects", (err, array) ->
      if not err and array and array.length
        projects = []
        return tools.asyncParallel array, (pid) ->
          return db.projects.getData pid, (err, project) ->
            if not err and project
              projects.push project
              return tools.asyncDone array, ->
                return tools.asyncOpt fn, null, projects
            return tools.asyncOpt fn, err, []
      return tools.asyncOpt fn, err, []

  mod.getData = (pid, fn) ->
    client.hgetall "projects:#{pid}", (err, project) ->
      if not err and project
        return db.projects.getUsers pid, (err, array) ->
          project.users = array
          return tools.asyncOpt fn, err, project
      return tools.asyncOpt fn, err, null

  mod.getUsers = (pid, fn) ->
    client.smembers "projects:#{pid}:users", (err, array) ->
      if not err and array and array.length
        users = []
        return tools.asyncParallel array, (uid) ->
          db.contacts.getInfo uid, (err, user) ->
            users.push user
            return tools.asyncDone array, ->
              return tools.asyncOpt fn, null, users
      return tools.asyncOpt fn, err, []

  mod.add = (uid, name, fn) ->
    client.incr 'projects:next', (err, val) ->
      if not err
        dir = "./uploads/#{val}"
        fs.mkdir dir, cfg.DIRECTORY_PERMISSION, (err) ->
          fs.mkdir "#{dir}/video", cfg.DIRECTORY_PERMISSION
          fs.mkdir "#{dir}/image", cfg.DIRECTORY_PERMISSION
        project = {}
        project.id = val
        project.name = name
        project.owner = uid
        project.start = new Date
        project.status = 'new'
        client.hmset "projects:#{val}", project
        client.sadd "projects:#{val}:users", uid
        client.sadd "users:#{uid}:projects", val

        return db.canvases.add val, null, null, ->
          if !err
            return tools.asyncOpt(fn, null, project)

      return tools.asyncOpt fn, err, null

  mod.deleteCanvases = (pid, fn) ->
    client.smembers "projects:#{pid}:canvases", (err, array) ->
      client.del "projects:#{pid}:canvases"
      if not err and array and array.length
        return tools.asyncParallel array, (cid) ->
          client.del "canvases:#{cid}"
          return tools.asyncDone array, ->
            return tools.asyncOpt fn, null, pid
      return tools.asyncOpt fn, err, pid

  mod.deleteUsers = (pid, fn) ->
    client.smembers "projects:#{pid}:users", (err, array) ->
      if not err and array and array.length
        db.contacts.deleteContacts pid, array, 0, fn
      client.del "projects:#{pid}:users"
      return tools.asyncOpt fn, err, pid

  mod.deleteActions = (pid, type, fn) ->
    client.lrange "projects:#{pid}:#{type}", 0, -1, (err, array) ->
      client.del "projects:#{pid}:#{type}"
      if not err and array and array.length
        return tools.asyncParallel array, (aid) ->
          client.del "actions:#{aid}"
          return tools.asyncDone array, ->
            return tools.asyncOpt fn, null, pid
      return tools.asyncOpt fn, err, pid

  mod.delete = (pid, fn) ->
    db.projects.deleteCanvases pid
    db.projects.deleteUsers pid
    db.projects.deleteActions pid, 'chat'
    db.projects.deleteActions pid, 'element'
    db.projects.deleteActions pid, 'comment'
    client.del "projects:#{pid}", fn

  mod.setProperties = (pid, properties, fn) ->
    purifiedProp = tools.purify properties
    return client.hmset "projects:#{pid}", purifiedProp, fn

  mod.invite = (pid, id, user, fn) ->
    if user.id is id
      return tools.asyncOptError fn, 'Cannot invite yourself'
    # Check if user exists
    return client.exists "users:#{user.id}", (err, val) ->
      if not err and val
        client.sadd "projects:#{pid}:unconfirmed", user.id
        db.activities.add pid, user.id, 'projectInvite', id
        return tools.asyncOpt fn, null, user

      if not val
        return tools.asyncOpt fn, new Error 'Record not found'

      return tools.asyncOpt fn, err

  mod.inviteSocial = (pid, provider, providerId, fn) ->
    #TODO
    console.log 'invite social'

  mod.inviteEmail = (pid, id, email, fn) ->
    db.users.findByEmail email, (err, user) ->
      return tools.asyncOpt fn, err if err

      if not user
        hash = tools.hash email
        password = tools.genPass();
        return db.users.add {
          hash: hash
          password: password
          status: 'unconfirmed'
          provider: 'local'
        }, null, [
          {
            value: email
            type: 'main'
          }
        ], (err, contact) ->
          return process.nextTick(-> fn err) if err
          if not contact
            return process.nextTick ->
              fn new Error 'Can not create user.'
          client.sadd "users:#{id}:unconfirmed", contact.id
          client.sadd "users:#{contact.id}:requests", id
          return db.users.findById id, (err, user) ->
            return smtp.regPropose user, contact, hash, fn
      return mod.invite pid, id, user, fn

  mod.inviteLink = (pid, fn) ->
    #TODO
    console.log 'invite link'

  mod.accept = (pid, id, fn) ->
    # Get project members
    client.smembers "projects:#{pid}:users", (err, array) ->
      if not err and array and array.length
        return tools.asyncParallel array, (cid) ->
          # Add the user as a contact to all project members
          client.sadd "users:#{cid}:contacts", id
          # And vise-versa
          client.sadd "users:#{id}:contacts", cid
          return tools.asyncDone array, ->
            # Add the user to the project
            client.smove "projects:#{pid}:unconfirmed", "projects:#{pid}:users", id
            # Add the project to the user
            client.sadd "users:#{id}:projects", pid
            return fn null
      fn err

  mod.decline = (pid, id, fn) ->
    client.srem "projects:#{pid}:unconfirmed", id, fn

  mod.remove = (pid, id, fn) ->
    # Remove project from user projects
    client.srem "users:#{id}:projects", pid
    # Get project members
    client.smembers "projects:#{pid}:users", (err, array) ->
      if not err and array and array.length
        db.contacts.recalculate id, array, pid
        return tools.asyncParallel array, (left, cid) ->
          # Recalculate member contacts
          db.contacts.recalculate cid, [id], pid
          return tools.asyncDone array, ->
            # Remove user from project members
            client.srem "projects:#{pid}:users", id
            return tools.asyncOpt fn, null
      return tools.asyncOpt fn, err

  mod.confirm = (aid, uid, answer, fn) ->
    return client.hget "activities:#{aid}", 'project', (err, val) ->
      if not err and val
        if answer is 'true'
          client.hset "activities:#{aid}", 'status', 'accepted'
          return db.projects.accept val, uid, fn
        client.hset "activities:#{aid}", 'status', 'declined'
        return db.projects.decline val, uid, fn
      return tools.asyncOpt fn, err, val

  mod.set = (id, pid, fn) ->
    client.set "users:#{id}:current", pid, fn

  mod.current = (id, fn) ->
    client.get "users:#{id}:current", fn

  return mod

