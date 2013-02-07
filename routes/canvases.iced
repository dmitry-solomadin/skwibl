exports.configure = (app) ->

  app.post '/canvases/addEmpty', @ctrls.mid.isAuth, @ctrls.canvases.addEmpty

  app.post '/canvases/initializeFirst', @ctrls.mid.isAuth, @ctrls.canvases.initFirst
