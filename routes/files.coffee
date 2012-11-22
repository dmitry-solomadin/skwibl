ctrls = require '../controllers'

exports.configure = (app, passport) ->

  app.get '/files', ctrls.mid.isAuth, ctrls.files.get

  app.get '/files/:pid', ctrls.mid.isAuth, ctrls.files.project

  app.get '/files/:pid/:fid', ctrls.mid.isAuth, ctrls.mid.isMember, ctrls.mid.isFileInProject, ctrls.files.file

  app.post '/files/add', ctrls.mid.isAuth, ctrls.files.add

  app.post '/files/delete', ctrls.mid.isAuth, ctrls.files.delete

  app.post '/files/update', ctrls.mid.isAuth, ctrls.files.update

  #TODO change to work with mid.isMember (be ready to listen req.data event understand how to use req.pause() properly)
  app.post '/file/upload', ctrls.mid.isAuth, /*ctrls.mid.isMember,*/ ctrls.files.upload
