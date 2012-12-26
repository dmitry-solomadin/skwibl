ctrls = require '../controllers'

exports.configure = (app, passport) ->

  app.get '/dev/player', ctrls.mid.isAuth, ctrls.dev.player

  app.get '/dev/conns', ctrls.mid.isAuth, ctrls.dev.conns

  app.post '/dev/drive', ctrls.mid.isAuth, ctrls.dev.integration