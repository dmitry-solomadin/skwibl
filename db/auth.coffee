
_ = require 'underscore'

smtp = require '../smtp'
tools = require '../tools'

exports.setUp = (client, db) ->

  mod = {}

  mod.findOrCreate = (profile, token, fn) ->
    emails = profile.emails
    return db.users.findByEmails emails, (err, user) ->
      if not user
        email = emails[0].value
        password = tools.genPass()
        return db.users.add
          displayName: profile.displayName
          providerId: profile.id
          password: password
          picture: profile._json.picture
          status: 'registred'
          provider: profile.provider
        , profile.name, emails, (err, user) ->
          if user
            db.auth.connect user.id, user.provider, token
            return smtp.sendRegMail user, fn
          return tools.asyncOpt fn, err, user
      if not user.picture
        user.picture = profile._json.picture;
        db.users.setProperties user.id, picture: user.picture
      purifiedName = tools.purify profile.name
      if not _.isEqual user.name, purifiedName
        user.name = _.extend purifiedName, user.name
        db.users.setName user.id, user.name
      diff = _.difference profile.emails, user.emails
      if diff.length
        user.emails.concat diff
        db.users.addEmails user.id, user.emails
      db.auth.connect user.id, profile.provider, token
      if user.status is 'unconfirmed'
        return db.users.persist user, fn
      if user.status is 'deleted'
        return db.users.restore user, fn
      return tools.asyncOpt fn, err, user

  mod.connections = (id, fn) ->
    client.hgetall "users:#{id}:connections", fn

  mod.connect = (id, provider, token, fn) ->
    client.hset "users:#{id}:connections", provider, token, fn

  mod.disconnect = (id, provider, fn) ->
    client.hdel "users:#{id}:connections", provider, fn

  return mod
