exports.configure = (app) ->

  app.post '/forgotpassword', @ctrls.support.passwordRecovery

  app.get '/checkmail', @ctrls.support.checkMail
