
/**
 * Module dependencies.
 */

var express = require('express')
  , flash = require('connect-flash')
  , ect = require('ect')
  , path = require('path');

var routes = require('../routes')
  , ctrls = require('../controllers')
  , helpers = require('../helpers')
  , db = require('../db')
  , cfg = require('../config');

var passportUp = require('./passport');
var moment = require('moment');

exports.setUp = function() {

  var app = express();

  var passport = passportUp.setUp();

  var viewsDir = path.join(__dirname, '../views')
    , assetsDir = path.join(__dirname, '../assets')
    , vendorDir = path.join(__dirname, '../vendor');

  app.configure('development', function(){
    app.use(express.errorHandler({
      dumpExceptions: true,
      showStack: true
    }));
  });

  app.configure('production', function(){
    app.use(express.errorHandler());
  });

  app.configure(function(){
    app.set('port', cfg.PORT);
    app.set('host', cfg.HOST);
    app.set('views', viewsDir);
    app.engine('ect', ect({
      cache: true
    , watch: true
    , root: viewsDir
    }).render);
    app.set("view engine", 'ect');
    app.use(express.favicon(assetsDir + '/images/butterfly-tiny.png'));
    app.set('view options', {layout: false});
    app.use(express.logger('dev'));
    app.use(express.bodyParser());
    app.use(express.methodOverride());
    app.use(express.cookieParser());
    app.use(express.session({
      key: cfg.SESSION_KEY
    , secret: cfg.SITE_SECRET
    , store: db.sessions.createStore(express)
    }));
    app.use(passport.initialize());
    app.use(passport.session());

    app.use(function(req, res, next) {
      res.locals.req = req;
      next()
    });
    app.use(flash());
    app.use(app.router);
    app.use(express.static(assetsDir));
    app.use(express.static(vendorDir));
    app.use(ctrls.aux.notFound);
    //   app.use(ctrls.error);
  });

  app.locals = {};

  for (method in helpers.application_helper) {
    app.locals[method] = helpers.application_helper[method];
  }

  app.locals.moment = moment;

  routes.configure(app, passport);

  return app;
};

exports.start = function(app){
  console.log("Express server listening on " +
  app.get('host') + ":" + app.get('port') +
  " in " + app.settings.env + " mode");
};