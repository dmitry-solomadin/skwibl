exports.configure = (app) ->

  app.get '/about_us', @ctrls.public.aboutUs

  app.get '/contact_us', @ctrls.public.contacts

  app.get '/team', @ctrls.public.team

  app.get '/tour', @ctrls.public.tour

#   app.get '/tour/:chapter?', @ctrls.public.tourChapter
