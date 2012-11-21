
express = require 'express'
flash = require 'connect-flash'
ect = require 'ect'
path = require 'path'

routes = require '../routes'
ctrls = require '../controllers'
helpers = require '../helpers'
db = require '../db'
cfg = require '../config'

passportUp = require './passport'
moment = require 'moment'

exports.setUp = ->

  app = express()

  passport = passportUp.setUp()

  viewsDir = path.join __dirname, '../views'
  assetsDir = path.join __dirname, '../assets'
  vendorDir = path.join __dirname, '../vendor'

  app.configure 'development', ->
    app.use express.errorHandler {
      dumpExceptions: true
      showStack: true
    }

  app.configure 'production', ->
    app.use express.errorHandler()

  app.configure ->
    app.set 'port', cfg.PORT
    app.set 'host', cfg.HOST
    app.set 'views', viewsDir
    app.engine 'ect', ect({
      cache: true
      watch: true
      root: viewsDir
    }).render
    app.set 'view engine', 'ect'
    app.use express.favicon "#{assetsDir}/images/butterfly-tiny.png"
    app.set 'view options', {layout: false}
    app.use express.logger 'dev'
    app.use express.bodyParser()
    app.use express.methodOverride()
    app.use express.cookieParser()
    app.use express.session {
      key: cfg.SESSION_KEY
      secret: cfg.SITE_SECRET
      store: db.sessions.createStore express
    }
    app.use passport.initialize()
    app.use passport.session()

    app.use (req, res, next) ->
      res.locals.req = req
      next()
    app.use flash()
    app.use app.router
    app.use express.static assetsDir
    app.use express.static vendorDir
    app.use ctrls.aux.notFound
    #   app.use(ctrls.error);

  app.locals = {}

  for method of helpers.application_helper
    app.locals[method] = helpers.application_helper[method]

  app.locals.moment = moment

  routes.configure app, passport

  return app

exports.start = (app) ->
  console.log "Express server listening on
  #{app.get('host')}:#{app.get('port')} in
  #{app.settings.env} mode"