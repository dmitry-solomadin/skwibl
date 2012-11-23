ctrls = require '../controllers'

exports.configure = (app, passport) ->

  app.get '/users/:id', ctrls.users.profile

  app.get '/users/:id/edit', ctrls.mid.isAuth, ctrls.mid.isCurrentUser, ctrls.users.edit

  app.post '/users/:id/update', ctrls.mid.isAuth, ctrls.mid.isCurrentUser, ctrls.users.update

  app.post '/users/delete', ctrls.mid.isAuth, ctrls.users.delete
