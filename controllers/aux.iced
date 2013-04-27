helpers = require '../helpers'

#
# GET
# Dummy function for passport social strategies
#
exports.empty = (req, res)=>

#
# All
# 404 page
#
exports.notFound = (req, res) =>
  if req.method is 'GET'
    return res.render '404', title: 404
  return res.json
    success: false
    message: 'route not found'

#
# ALL
# error page
#
exports.error = (err, req, res, next) =>
  if req.method is 'GET'
    res.render '404', title: 'Error'
  return res.json
    success: false
    message: err

#
# All
# add helpers
#
exports.helpers = (req, res, next) =>
  res.locals helpers: helpers
  res.locals.helpers.users.user = req.user
  res.locals.helpers.flash.req = {}
  res.locals.helpers.flash.req.session = req.session
  res.locals.helpers.flash.req.flash = req.flash
  res.locals.originalUrl = req.originalUrl
  next()

#
# All
# define locale
#
exports.locale = (req, res, next) =>
  lang = req.query.lang
  if lang
    req.i18n.setLocale lang
    req.session.currentLocale = lang
    return next()
  lang = req.session.currentLocale
  if lang
    req.i18n.setLocale lang
    return next()
  lang = req.i18n.prefLocale
  req.i18n.setLocale lang
  req.session.currentLocale = lang
  return next()
