
connect_redis = require 'connect-redis'

exports.setUp = (client, db) =>

  mod = {};

  mod.createStore = (express) =>
    sessionStore = connect_redis express
    return new sessionStore {
      client: client
      ttl: @cfg.SESSION_DURATION
    }

  mod.get = (sessionId, fn) =>
    return client.get "sess:#{sessionId}", fn

  mod.touch = (sessionId, fn) =>
    client.expire "sess:#{sessionId}", @cfg.SESSION_DURATION, fn

  return mod
