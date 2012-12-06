db = require '../db'
smtp = require '../smtp'

#
# POST
# Password recovery
#
exports.passwordRecovery = (req, res) ->
  email = req.body.email
  db.users.findByEmail email, (err, user) ->
    return res.send no if err
    return res.send no unless user
    return smtp.passwordSend req, res, user, ->
      return res.send no if err
      return res.send yes

#
# GET
# Check mail page
#
exports.checkMail = (req, res) ->
  res.render 'index',
    template: '/users/check_mail'
    message: req.flash 'message'
