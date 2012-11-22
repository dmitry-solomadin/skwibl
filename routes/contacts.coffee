ctrls = require '../controllers'

exports.configure = (app, passport) ->

  app.get '/contacts', ctrls.mid.isAuth, ctrls.contacts.get
