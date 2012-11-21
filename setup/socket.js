
/**
 * Module dependencies.
 */

var cookie = require('cookie')
  , io = require('socket.io')
  , redis = require('redis');

var sockets = require('../sockets')
  , cfg = require('../config')
  , db = require('../db');

exports.setUp = function(server) {

  var sio = io.listen(server);

  var pub = redis.createClient()
    , sub = redis.createClient()
    , client = redis.createClient();

  sio.configure('development', function() {
    sio.set('log level', 3);
  });

  sio.configure('production', function() {
    sio.set('log level', 0);
  });

  sio.configure(function() {

    //   io.disable('browser client cache');

    sio.set('store', new io.RedisStore({
      redisPub : pub
    , redisSub : sub
    , redisClient : client
    }));

    sio.set('authorization', function(data, accept){
      if (!data.headers.cookie) {
        return accept('Session cookie required.', false);
      }
      data.cookie = cookie.parse(data.headers.cookie);
      data.sessionId = data.cookie[cfg.SESSION_KEY].substring(2, 26);
      db.sessions.get(data.sessionId, function(err, session){
        if(err) {
          return accept('Error in session store.', false);
        } else if(!session) {
          return accept('Session not found.', false);
        }
        var sessionData = JSON.parse(session)
          , user = sessionData.passport.user;
        if(!user) {
          return accept('User not logged in', false);
        }
        data.user = user;
        data.session = sessionData;
        return accept(null, true);
      });
    });

  });

  sockets.configure(sio);

  process.on('uncaughtException', function(err) {
    console.log(err);
  });

};

exports.start = function(){
  console.log('socket.io serer is started on ' +
  cfg.HOST + ':' + cfg.SOCKET_PORT + ' in ' +
  cfg.ENVIRONMENT + ' mode');
};
