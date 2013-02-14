exports.configure = (app) ->

  app.get '/contacts', @ctrls.mid.isAuth, @ctrls.contacts.get
