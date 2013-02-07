exports.configure = (app) ->

  app.get '/activities', @ctrls.mid.isAuth, @ctrls.activities.index
