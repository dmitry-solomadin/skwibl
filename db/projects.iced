fs = require 'fs'

tools = require '../tools'
cfg = require '../config'

smtp = require '../smtp'

exports.setUp = (client, db) ->

  mod = {}

  # get all the projects that are available for the user
  mod.index = (uid, fn) ->
    await client.sort "users:#{uid}:projects", "by", "projects:*->createdAt", "desc", defer(err, array)
    projects = []

    if not err and array and array.length
      getProjectData = (pid, autocb) ->
        await db.projects.getData pid, defer(err, project)
        projects.push project if not err and project

      await getProjectData pid, defer() for pid in array

    return tools.asyncOpt fn, null, projects

  mod.getData = (pid, fn) ->
    client.hgetall "projects:#{pid}", (err, project) ->
      if not err and project
        return db.projects.getUsers pid, (err, users) ->
          project.users = users
          return db.projects.getUnconfirmedUsers pid, users, (err, unconfirmedUsers) ->
            project.unconfirmedUsers = unconfirmedUsers
            return db.projects.getFiles pid, (err, files) ->
              project.files = files
              return db.commentTexts.getProjectTodos pid, 3, (err, todos) ->
                project.todos = todos
                return tools.asyncOpt fn, err, project
      return tools.asyncOpt fn, err, null

  mod.findById = (pid, fn) ->
    client.hgetall "projects:#{pid}", (err, project) ->
      tools.asyncOpt fn, err, project

  mod.getFiles = (pid, fn) ->
    client.smembers "projects:#{pid}:files", (err, fileIds) ->
      if not err and fileIds and fileIds.length
        files = []
        return tools.asyncParallel fileIds, (fid) ->
          db.files.findById fid, (err, file) ->
            files.push file
            return tools.asyncDone fileIds, ->
              tools.asyncOpt fn, null, files

      return tools.asyncOpt fn, err, []

  # list of users that confirmed invitations
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

  # list of users that are not confirmed invitations
  mod.getUnconfirmedUsers = (pid, confirmedUsers, fn) ->
    client.smembers "projects:#{pid}:unconfirmed", (err, unconfirmedUsersIds) ->
      if not err and unconfirmedUsersIds and unconfirmedUsersIds.length
        users = []
        return tools.asyncParallel unconfirmedUsersIds, (uid) ->
          db.contacts.getInfo uid, (err, user) ->
            users.push user
            return tools.asyncDone unconfirmedUsersIds, ->
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
        project.createdAt = new Date().getTime()
        project.start = new Date

        project.status = 'new'
        client.hmset "projects:#{val}", project
        client.sadd "projects:#{val}:users", uid
        client.sadd "users:#{uid}:projects", val

        return db.canvases.add val, null, null, (err, canvas) ->
          return tools.asyncOpt(fn, err, project)

      return tools.asyncOpt fn, err, null

  mod.deleteCanvases = (pid, fn) ->
    client.smembers "projects:#{pid}:canvases", (err, array) ->
      client.del "projects:#{pid}:canvases" unless err
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

  mod.deleteUnconfirmedUsers = (pid, fn) ->
    client.smembers "projects:#{pid}:unconfirmed", (err, array) ->
      client.del "projects:#{pid}:unconfirmed" unless err
      if not err and array and array.length
        return tools.asyncParallel array, (cid) ->
          #TODO
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

  mod.deleteInvitations = (pid, fn) ->
    client.del "projects:#{pid}:unconfirmed"

    # remove projectInvite activities one by one
    await client.smembers "activities:projectInvite:#{pid}", defer(err, aids)
    if not err and aids
      deleteActivity = (aid, autocb) -> await db.activities.delete aid, defer()
      await deleteActivity aid, defer() for aid in aids

    # remove projectInvite bucket
    client.del "activities:projectInvite:#{pid}"

    tools.asyncOpt fn, err, null

  mod.delete = (pid, fn) ->
    db.projects.deleteCanvases pid
    db.projects.deleteUsers pid
    db.projects.deleteActions pid, 'chat'
    db.projects.deleteActions pid, 'element'
    db.projects.deleteActions pid, 'comment'
    db.projects.deleteInvitations pid
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
        return client.sismember "projects:#{pid}:unconfirmed", user.id, (err, val) ->
          if not err and not val
            client.sadd "projects:#{pid}:unconfirmed", user.id
            db.activities.add pid, user.id, 'projectInvite', id
            return tools.asyncOpt fn, err, user
          return tools.asyncOptError fn, "This user has already been invited to project.", null
      if not val
        return tools.asyncOpt fn, new Error 'Record not found'

      return tools.asyncOpt fn, err

  mod.inviteSocial = (pid, provider, providerId, fn) ->
    #TODO
    console.log 'invite social'

  mod.inviteEmail = (pid, id, email, fn) ->
    unless email and tools.isEmail email
      return tools.asyncOptError fn, "Please, enter an email."

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
      return db.projects.invite pid, id, user, fn

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

  # remove user from project.
  mod.remove = (pid, id, fn) ->
    # Remove project from user projects
    client.srem "users:#{id}:projects", pid
    # Get project members
    client.smembers "projects:#{pid}:users", (err, array) ->
      if not err and array and array.length
        db.contacts.recalculate id, array, pid
        return tools.asyncParallel array, (cid) ->
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

