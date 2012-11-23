
db = require '../db'

exports.currentUser = (id) ->
  return id is this.req.user.id if id
  return this.req.user

exports.flashError = ->
  return this.req.flash 'error'

exports.flashMessage = ->
  return this.req.flash 'message'

exports.flashWarning = ->
  return this.req.flash 'warning'

exports.errorMessages = ->
  return this.req.flash 'objectErrors'
