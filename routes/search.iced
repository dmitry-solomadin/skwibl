exports.configure = (app) ->

  app.get '/search', @ctrls.mid.isAuth, @ctrls.search.search
