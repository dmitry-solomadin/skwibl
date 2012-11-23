
cookie = require 'cookie'
io = require 'socket.io'
redis = require 'redis'

sockets = require '../sockets'
cfg = require '../config'
db = require '../db'

exports.setUp = (server) ->

  sio = io.listen server

  pub = redis.createClient()
  sub = redis.createClient()
  client = redis.createClient()

  sio.configure 'development', ->
    sio.set 'log level', 3

  sio.configure 'production', ->
    sio.set 'log level', 0

  sio.configure ->

    #   io.disable 'browser client cache'

    sio.set 'store', new io.RedisStore
      redisPub : pub
      redisSub : sub
      redisClient : client

    sio.set 'authorization', (data, accept) ->
      unless data.headers.cookie
        return accept 'Session cookie required.', no
      data.cookie = cookie.parse data.headers.cookie
      data.sessionId = data.cookie[cfg.SESSION_KEY].substring 2, 26
      db.sessions.get data.sessionId, (err, session) ->
        if err
          return accept 'Error in session store.', no
        else unless session
          return accept 'Session not found.', no
        sessionData = JSON.parse session
        user = sessionData.passport.user
        unless user
          return accept 'User not logged in', no
        data.user = user
        data.session = sessionData
        return accept null, true


  sockets.configure sio

  process.on 'uncaughtException', (err) ->
    console.log err

exports.start = ->
  console.log "socket.io serer is started on
  #{cfg.HOST}:#{cfg.SOCKET_PORT} in
  #{cfg.ENVIRONMENT} mode"
