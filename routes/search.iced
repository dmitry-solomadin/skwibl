ctrls = require '../controllers'

exports.configure = (app, passport) ->

  app.get '/search', ctrls.mid.isAuth, ctrls.search.search
