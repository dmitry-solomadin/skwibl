
connect_redis = require 'connect-redis'

exports.createStore = (express) =>
  sessionStore = connect_redis express
  return new sessionStore {
    client: @client
    ttl: @cfg.SESSION_DURATION
  }

exports.get = (sessionId, fn) =>
  return @client.get "sess:#{sessionId}", fn

exports.touch = (sessionId, fn) =>
  @client.expire "sess:#{sessionId}", @cfg.SESSION_DURATION, fn
