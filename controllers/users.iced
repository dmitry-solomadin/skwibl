db = require '../db'

tools = require '../tools'

#
# GET
# Redirect to user profile
#
exports.profile = (req, res) ->
  res.render 'users/show'

#
# GET
# Edit personal profile
#
exports.edit = (req, res) ->
  res.render 'index', template: 'users/edit'

#
# POST
# Update user profile info
#
exports.update = (req, res) ->
  db.users.setProperties req.params.id, req.body.user, (err) ->
    if err
      req.flash 'error', 'Something wrong happened.'
      res.redirect "/users/#{req.params.id}/edit"

    if req._passport and req._passport.session.user
      return db.users.findById req.user.id, (err, user) ->
        req._passport.session.user = user
        req.user = user
        res.redirect "/users/#{req.params.id}/edit"
    res.redirect "/users/#{req.params.id}/edit"

#
# POST
# Delete user profile
#
exports.delete = (req, res) ->
  db.users.delete req.user.id, (err) ->
    if err
      req.flash 'error', err
      return res.redirect '/'
    req.flash 'error', 'Your profile has been successfuly deleted.'
    return res.redirect '/'
