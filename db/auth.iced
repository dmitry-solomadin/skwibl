_ = require 'lodash'

exports.findOrCreate = (profile, token, secret, fn) =>
  emails = profile.emails
  return @db.users.findByEmails emails, (err, user) =>
    unless user
      email = emails[0].value
      password = @tools.genPass()
      return @db.users.add
        displayName: profile.displayName
        providerId: profile.id
        password: password
        picture: profile._json.picture?.data?.url or profile._json.picture or profile._json.pictureUrl
        status: 'registred'
        provider: profile.provider
      , profile.name, emails, (err, user) =>
        if user
          @db.auth.connect user.id, user.provider,
            token: token
            secret: secret
          , @tools.logError
          return @smtp.sendRegMail user, fn
        return @tools.asyncOpt fn, err, user
    unless user.picture
      user.picture = profile._json.picture?.data?.url or profile._json.picture or profile._json.pictureUrl
      @db.users.setProperties user.id, picture: user.picture
    purifiedName = @tools.purify profile.name
    unless _.isEqual user.name, purifiedName
      user.name = _.extend purifiedName, user.name
      @db.users.setName user.id, user.name
    diff = _.difference _.pluck(profile.emails, 'value'), _.pluck(user.emails, 'value')
    if diff.length
      user.emails.concat diff.map (email) -> value: email
      @db.users.addEmails user.id, user.emails
    @db.auth.connect user.id, profile.provider,
      token: token
      secret: secret
    , @tools.logError
    if user.status is 'unconfirmed'
      return @db.users.persist user, fn
    if user.status is 'deleted'
      return @db.users.restore user, fn
    return @tools.asyncOpt fn, err, user

exports.connections = (id, fn) =>
  @client.smembers "users:#{id}:connections", fn

exports.getConnection = (id, provider, fn) =>
  @client.hgetall "users:#{id}:#{provider}", fn

exports.connect = (id, provider, connection, fn) =>
  @client.sadd "users:#{id}:connections", provider
  @client.hmset "users:#{id}:#{provider}", connection, fn

exports.setConnection = (id, provider, connection, fn) =>
  @client.hmset "users:#{id}:#{provider}", connection, fn

exports.disconnect = (id, provider, fn) =>
  @client.srem "users:#{id}:connections", provider
  @client.del "users:#{id}:#{provider}", fn
