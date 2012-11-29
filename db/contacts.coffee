
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
    client.smembers "users:#{id}:projects", (err, array) ->
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
    return db.projects.remove pid, array[index], (err) ->
      return process.nextTick ->
        db.contacts.deleteContacts pid, array, ++index, fn

#   mod.inviteEmailUserContact = function(id, email, fn) {
#     db.users.findByEmail(email, function(err, contact) {
#       if(err) {
#         return process.nextTick(function () {
#           fn(err);
#         });
#       }
#       if(contact) {
#         return db.users.addContact(id, contact.id, fn);
#       }
#       var hash = tools.hash(email)
#       , password = tools.genPass();
#       return db.users.add({
#         hash: hash,
#         password: password,
#         status: 'unconfirmed',
#         provider: 'local'
#       }, null, [{
#         value: email,
#         type: 'main'
#       }], function(err, contact) {
#         if (err) {
#           return process.nextTick(function () {
#             fn(err);
#           });
#         }
#         if (!contact) {
#           return process.nextTick(function () {
#             fn(new Error('Can not create user.'));
#           });
#         }
#         client.sadd('users:' + id + ':unconfirmed', contact.id);
#         client.sadd('users:' + contact.id + ':requests', id);
#         return db.users.findById(id, function(err, user) {
#           return smtp.regPropose(user, contact, hash, fn);
#         });
#         //       return db.expireUser(contact, db.users.findById(id, function(err, user) {
#         //         return smtp.regPropose(user, contact, hash, fn);
#         //       }));
#       });
#     });
#   };
#
#   mod.confirmUserContact = function(id, cid, accept, fn) {
#     if(accept) {
#       client.smove('users:' + id + ':requests', 'users:' + id + ':contacts', cid);
#       return client.smove('users:' + cid + ':unconfirmed', 'users:' + cid + ':contacts', id, fn);
#       // TODO send notification to a new fried
#     }
#     client.srem('users:' + id + ':requests', cid);
#     return client.srem('users:' + cid + 'unconfirmed', id, fn);
#   };

  return mod
