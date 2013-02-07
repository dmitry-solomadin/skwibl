
express = require 'express'
flash = require 'connect-flash'
ect = require 'ect'
path = require 'path'

moment = require 'moment'

routes = require '../routes'
ctrls = require '../controllers'
helpers = require '../helpers'
db = require '../db'
cfg = require '../config'

passportUp = require './passport'

exports.setUp = (logger) ->

  app = express()

  passport = passportUp.setUp()

  viewsDir = path.join __dirname, '../views'
  assetsDir = path.join __dirname, '../assets'

  logStream =
    write: (message, encoding) ->
      logger.info message

  app.configure 'development', ->
    app.use express.errorHandler {
      dumpExceptions: true
      showStack: true
    }

  app.configure 'production', ->
    app.use express.errorHandler()

  app.configure ->
    app.set 'views', viewsDir
    app.engine 'ect', ect({
      cache: true
      watch: true
      root: viewsDir
    }).render
    app.set 'view engine', 'ect'
    app.use express.logger stream: logStream, format: 'dev'
    app.enable 'trust proxy'
    app.use express.favicon "#{assetsDir}/images/butterfly-tiny.png"
    app.set 'view options', {layout: false}
    app.use express.json()
    app.use express.urlencoded()
    app.use express.methodOverride()
    app.use express.cookieParser()
    app.use express.session {
      key: cfg.SESSION_KEY
      secret: cfg.SITE_SECRET
      store: db.sessions.createStore express
    }
    app.use passport.initialize()
    app.use passport.session()
    app.use '/file/upload', ctrls.mid.isAuth
    app.use '/file/upload', ctrls.files.upload
    app.use (req, res, next) ->
      #TODO change to req.user, req.flash
      #TODO temporary fix, find a nicer way
      res.locals helpers: helpers
      res.locals.helpers.general.req = req
      res.locals.originalUrl = req.originalUrl
#       res.locals.general.user = req.user
#       res.locals.general.flash = req.flash
      next()
    app.use flash()
    app.use app.router
    app.use express.static assetsDir
    app.use ctrls.aux.notFound
#     app.use(ctrls.aux.error);

  app.locals.moment = moment
  app.locals.passport = passport

  routes.configure app

  return app

exports.start = (logger) ->
  logger.info "Express server listening on
  #{cfg.HOST}:#{cfg.PORT} in
  #{cfg.ENVIRONMENT} mode"