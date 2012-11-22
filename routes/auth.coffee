ctrls = require '../controllers'

exports.configure = (app, passport) ->

  app.get '/', ctrls.auth.mainPage

  app.get '/registration', ctrls.auth.regPage

  app.post '/register', ctrls.auth.register

  app.post '/login', ctrls.auth.local passport

  app.get '/confirm/:hash', ctrls.auth.hash passport, ctrls.auth.confirm, ctrls.auth.logIn

  app.get '/auth/google', ctrls.auth.google passport, ctrls.aux.empty

  app.get '/auth/google/callback', ctrls.auth.googleCb passport, ctrls.auth.logIn

  app.get '/connect/google', ctrls.auth.connectGoogle

  app.get '/connect/google/callback', ctrls.auth.connectGoogleCb

  app.get '/auth/facebook', ctrls.auth.facebook passport, ctrls.aux.empty

  app.get '/auth/facebook/callback', ctrls.auth.facebookCb passport, ctrls.auth.logIn

  app.get '/connect/facebook', ctrls.auth.connectFacebook

  app.get '/connect/facebook/callback', ctrls.auth.connectFacebookCb

  app.get '/auth/linkedin', ctrls.auth.linkedin passport

  app.get '/auth/linkedin/callback', ctrls.auth.linkedinCb passport, ctrls.auth.logIn

  app.get '/connect/linkedin', ctrls.auth.connectLinkedin

  app.get '/connect/linkedin/callback', ctrls.auth.connectLinkedinCb

  app.get '/connect/dropbox', ctrls.auth.connectDropbox

  app.get '/connect/dropbox/callback', ctrls.auth.connectDropboxCb

  app.get '/connect/yahoo', ctrls.auth.connectYahoo

  app.get '/connect/yahoo/callback', ctrls.auth.connectYahooCb

  app.post '/auth/disconnect', ctrls.mid.isAuth, ctrls.auth.disconnect

  app.get '/logout', ctrls.mid.isAuth, ctrls.auth.logOut
