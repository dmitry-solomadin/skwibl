ctrls = require '../controllers'

exports.configure = (app, passport) ->

  app.get '/about_us', ctrls.public.aboutUs

  app.get '/contact_us', ctrls.public.contacts

  app.get '/team', ctrls.public.team