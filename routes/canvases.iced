exports.configure = (app) ->

  app.post '/canvases/linkscreenshot', @ctrls.mid.isAuth, @ctrls.mid.isMember, @ctrls.canvases.linkScreenshot

  app.post '/canvases/addEmpty', @ctrls.mid.isAuth, @ctrls.mid.isMember, @ctrls.canvases.addEmpty

  app.post '/canvases/initializeFirst', @ctrls.mid.isAuth, @ctrls.mid.isMember, @ctrls.canvases.initFirst
