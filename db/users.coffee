
_ = require 'underscore'

tools = require '../tools'

exports.setUp = (client, db) ->

  mod = {}

  mod.persist = (user, fn) ->
    emails = user.emails
    id = user.id
    client.hdel "users:#{id}", 'hash'
    client.del "hashes:#{user.hash}:uid"
    db.users.setProperties user.id, {
      status: 'registred'
    } ,(err, val) ->
      return tools.asyncOpt fn, err, user

  mod.add = (user, name, emails, fn) ->
    client.incr 'users:next', (err, val) ->
      if not err
        user.id = val + ''
        user.email = emails[0].value
        if user.provider is 'local'
          user.providerId = val
        umails = []
        emailtypes = []
        emailuid = []
        for email in emails
          value = email.value
          umails.push value
          emailtypes.push "emails:#{value}:type"
          emailtypes.push email.type
          emailuid.push "emails:#{value}:uid"
          emailuid.push val
        if user.hash
          client.set "hashes:#{user.hash}:uid", val
        client.hmset "users:#{val}", user
        purifiedName = tools.purify name
        if purifiedName
          client.hmset "users:#{val}:name", purifiedName
        client.sadd "users:#{val}:emails", umails
        client.mset emailtypes
        return client.mset emailuid, (err, results) ->
          if not err
            user.name = purifiedName
            user.emails = emails
            return tools.asyncOpt fn, null, user
          return tools.asyncOpt fn, err, null
      return tools.asyncOpt fn, err, null

  mod.restore = (id, fn) ->
    # Get contacts list
    client.smembers "users:#{id}:contacts", (err, array) ->
      if not err
        for cid in array
          # Add user from contacts' lists
          client.sadd "users:#{cid}:contacts"
    # Get unconfirmed contacts list
    client.smembers "users:#{id}unconfirmed", (err, array) ->
      if not err
        for cid in array
          # Add user from contacts' requests
          client.sadd "users:#{cid}:requests"
    # Set status to registred
    return client.hset "users:#{id}:emails" , 'status', 'registred', fn

  mod.delete = (id, fn) ->
    # Get contacts list
    client.smembers "users:#{id}:contacts", (err, array) ->
      if not err
        for cid in array
          # Delete user from contacts' lists
          client.srem "users:#{cid}:contacts"
    # Get unconfirmed contacts list
    client.smembers "users:#{id}unconfirmed", (err, array) ->
      if not err
        for cid in array
          # Delete user from contacts' requests
          client.srem "users:#{cid}:requests"
    # Set status to deleted
    return client.hset "users:#{id}:emails" , 'status', 'deleted', fn

  mod.findById = (id, fn) ->
    client.hgetall "users:#{id}", (err, user) ->
      if err or not user
        return tools.asyncOpt fn, err, null
      client.smembers "users:#{id}:emails",  (err, emails) ->
        if err
          return tools.asyncOpt fn, new Error "User #{id} have no emails"
        client.mget emails.map(tools.emailType), (err, array) ->
          types = array if array and array.length
          client.hgetall "users:#{id}:name", (err, name) ->
            umails = []
            for email, index in emails
              umails.push {
                value: email
                type: types[index]
              }
            user.emails = umails
            user.name = name
            return tools.asyncOpt fn, null, user

  mod.findByEmail = (email, fn) ->
    client.get "emails:#{email}:uid", (err, val) ->
      return tools.asyncOpt(fn, err, null) if err or not val
      return db.users.findById val, fn

  mod.findByEmails = (emails, fn) ->
    client.mget _.pluck(emails, 'value').map(tools.emailUid), (err, array) ->
      if not err and array
        for id in array
          if id
            return db.users.findById id, fn
      return tools.asyncOpt fn, err, null

  mod.findByHash = (hash, fn) ->
    client.get "hashes:#{hash}:uid", (err, val) ->
      if not err and val
        return db.users.findById val, fn
      return tools.asyncOpt fn, err, null

  mod.setProperties = (id, properties, fn) ->
    purifiedProp = tools.purify properties
    return client.hmset "users:#{id}" ,purifiedProp, fn

  mod.setName = (id, name, fn) ->
    purifiedName = tools.purify name
    return client.hmset "users:#{id}:name", purifiedName, fn

  mod.addEmails = (id, emails, fn) ->
    values = _.pluck(emails, 'value')
    client.sadd "users:#{id}:emails" , values
    for value, index in values
      client.mset "emails:#{value}:uid", id, "emails:#{value}:type", emails[index].type
    return tools.asyncOpt fn, null, values

  return mod
