/******************************************
 *          AUXILIARY FUNCTIONS           *
 ******************************************/


/**
 * Module dependencies.
 */

var connect_redis = require('connect-redis');

var cfg = require('../config');

exports.setUp = function(client) {

  var mod = {};

  mod.sessionStore = function(express) {
    var sessionStore = connect_redis(express);
    return new sessionStore({
      client: client
    , ttl: cfg.SESSION_DURATION
    });
  };

  mod.getSessionData = function(sessionId, fn) {
    return client.get('sess:' + sessionId, fn);
  };

  mod.touchSession = function(sessionId, fn) {
    client.expire('sess:' + sessionId, cfg.SESSION_DURATION, fn);
  };

  return mod;

};
