ctrls = require '../controllers'

exports.configure = (app, passport) ->

  app.get '/activities', ctrls.mid.isAuth, ctrls.activities.index
