
/**
 * Module dependencies.
 */

var express = require('express')
  , flash = require('connect-flash')
  , ejs_locals = require('ejs-locals');

var routes = require('./routes')
  , ctrls = require('./controllers')
  , db = require('./db')
  , cfg = require('./config');

var passport_config = require('./passport_config');

exports.setUp = function() {

  var app = express();

  var passport = passport_config.setUp();

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
    app.set('port', process.env.PORT || 3000);
    app.set('host', process.env.HOST || 'localhost');
    app.set('views', __dirname + '/views');
    app.engine('ejs', ejs_locals);
    app.set('view engine', 'ejs');
    app.use(express.favicon(__dirname +'/static/public/images/butterfly-tiny.png'));
    app.set('view options', {layout: false});
    app.use(express.logger('dev'));
    app.use(express.bodyParser());
    app.use(express.methodOverride());
    app.use(express.cookieParser());
    app.use(express.session({
      key: 'express.sid'
    , secret: cfg.SITE_SECRET
    , store: db.sessions.createStore(express)
    }));
    app.use(passport.initialize());
    app.use(passport.session());
    app.use(flash());
    app.use(app.router);
	  app.use(express.static(__dirname + '/assets'));
    app.use(express.static(__dirname + '/static'));
    app.use(ctrls.aux.notFound);
    //   app.use(ctrls.error);
  });

  routes.configure(app, passport);

  return app;
};

exports.start = function(app){
  console.log("Express server listening on " +
  app.get('host') + ":" + app.get('port') +
  " in " + app.settings.env + " mode");
};