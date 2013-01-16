
smtp = require '../smtp'
tools = require '../tools'

exports.setUp = (client, db) ->

  mod = {}

  mod.getInfo = (id, fn) ->
    client.hmget "users:#{id}", 'id', 'provider', 'providerId', 'displayName', 'picture', (err, array) ->
      if not err and array
        user = {}
        user.id = array[0]
        user.provider = array[1]
        user.providerId = array[2]
        user.displayName = array[3]
        user.picture = array[4]
        return client.hgetall "users:#{id}:name", (err, name) ->
          user.name = name
          return tools.asyncOpt fn, err, user
      return tools.asyncOpt fn, err, null

  mod.getField = (id, field, fn) ->
    client.smembers "users:#{id + field}", (err, array) ->
      if not err and array and array.length
        contacts = []
        return tools.asyncParallel array, (cid) ->
          db.contacts.getInfo cid, (err, contact) ->
            contacts.push contact
            return tools.asyncDone array, ->
              return tools.asyncOpt fn, null, contacts
      return tools.asyncOpt fn, err, []

  mod.get = (id, fn) ->
    db.contacts.getField id, ':contacts', (err, contacts) ->
      return tools.asyncOpt fn, err, contacts

  mod.isContact = (id, cid, pid, fn) ->
    #Get user projects
    client.zrange "users:#{id}:projects", 0, -1, (err, array) ->
      if not err and array and array.length
        return tools.asyncParallel array, (project) ->
          if project isnt pid
            #Check if client belongs to another project
            client.sismember "projects:#{project}:users", (err, val) ->
              if not err and val
                return tools.asyncOpt fn, null, true
              return tools.asyncDone array, ->
                return tools.asyncOpt fn, null, no
      return tools.asyncOpt fn, null, no

  mod.add = (pid, id, fn) ->
    # Get project members
    client.smembers "projects:#{pid}:users", (err, array) ->
      if not err and array and array.length
        return tools.asyncParallel array, (cid) ->
          # Add the user as a contact to all project members
          client.sadd "users:#{cid}:contacts", id
          # And vise-versa
          client.sadd "users:#{id}:contacts", cid
          return tools.asyncDone array, ->
            return tools.asyncOpt fn, null, pid
      return tools.asyncOpt fn, err, pid

  mod.recalculate = (id, contacts, pid, fn) ->
    for cid in contacts
      db.contacts.isContact id, cid, pid, (err, val) ->
        if err or not val
          client.srem "users:#{id}:contacts", cid
          client.srem "users:#{cid}:contacts", id
    return tools.asyncOpt fn, null

  mod.deleteContacts = (pid, array, index, fn) ->
    if index is array.length
      client.del "projects:#{pid}:users"
      return tools.asyncOpt fn, null, pid
    return db.projects.remove pid, array[index], false, (err) ->
      return process.nextTick ->
        db.contacts.deleteContacts pid, array, ++index, fn

  return mod
