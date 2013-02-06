ctrls = require '../controllers'

exports.configure = (app) ->

  app.get '/tour/:chapter?', ctrls.support.tour

  app.post '/forgotpassword', ctrls.support.passwordRecovery

  app.get '/checkmail', ctrls.support.checkMail
