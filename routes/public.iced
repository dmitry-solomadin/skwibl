ctrls = require '../controllers'

exports.configure = (app, passport) ->

  app.get '/about_us', ctrls.publicPages.aboutUs

  app.get '/contact_us', ctrls.publicPages.contacts

  app.get '/team', ctrls.publicPages.team