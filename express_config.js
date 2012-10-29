
/**
 * Module dependencies.
 */

var express = require('express')
  , flash = require('connect-flash')
  , ect = require('ect');

var routes = require('./routes')
  , ctrls = require('./controllers')
  , helpers = require('./helpers')
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
    app.set('port', cfg.PORT);
    app.set('host', cfg.HOST);
    app.set('views', __dirname + '/views');
    app.engine('ect', ect({ cache: true, watch: true, root: __dirname + '/views' }).render);
    app.set("view engine", 'ect');
    app.use(express.favicon(__dirname +'/assets/images/butterfly-tiny.png'));
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
    app.use(flash());
    app.use(app.router);
	  app.use(express.static(__dirname + '/assets'));
    app.use(express.static(__dirname + '/vendor'));
    app.use(ctrls.aux.notFound);
    //   app.use(ctrls.error);
  });

//  app.locals = {
//    current_user: helpers.application_helper.current_user
//  };

  routes.configure(app, passport);

  return app;
};

exports.start = function(app){
  console.log("Express server listening on " +
  app.get('host') + ":" + app.get('port') +
  " in " + app.settings.env + " mode");
};