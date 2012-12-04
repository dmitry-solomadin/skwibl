
_ = require 'lodash'

smtp = require '../smtp'
tools = require '../tools'

exports.setUp = (client, db) ->

  mod = {}

  mod.findOrCreate = (profile, token, secret, fn) ->
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
            db.auth.connect user.id, user.provider,
              token: token
              secret: secret
            , tools.logError
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
      db.auth.connect user.id, profile.provider,
        token: token
        secret: secret
      , tools.logError
      if user.status is 'unconfirmed'
        return db.users.persist user, fn
      if user.status is 'deleted'
        return db.users.restore user, fn
      return tools.asyncOpt fn, err, user

  mod.connections = (id, fn) ->
    client.smembers "users:#{id}:connections", fn

  mod.getConnection = (id, provider, fn) ->
    client.hgetall "users:#{id}:#{provider}", fn

  mod.connect = (id, provider, connection, fn) ->
    client.sadd "users:#{id}:connections", provider
    client.hmset "users:#{id}:#{provider}", connection, fn

  mod.setConnection = (id, provider, connection, fn) ->
    client.hmset "users:#{id}:#{provider}", connection, fn

  mod.disconnect = (id, provider, fn) ->
    client.srem "users:#{id}:connections", provider
    client.del "users:#{id}:#{provider}", fn

  return mod
