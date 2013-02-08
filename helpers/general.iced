cfg = require '../config'

exports.isProduction = ->
  return cfg.ENVIRONMENT is 'production'

exports.getDropboxKey = -> cfg.DROPBOX_APP_KEY
