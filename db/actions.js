/******************************************
 *                ACTIONS                 *
 ******************************************/


/**
 * Module dependencies.
 */

var tools = require('../tools')
  , cfg = require('../config');

exports.setUp = function(client, db) {

  var mod = {};

  mod.add = function(project, owner, type, data, fn) {
    client.incr('actions:next', function(err, val) {
      if(!err) {
        var action = {};
        action.project = project;
        action.owner = owner;
        action.type = type;
        action.time = new Date;
        action.data = data;
        client.hmset('actions:' + val, action);
        client.rpush('projects:' + project + ':' + type, val);
        return tools.asyncOpt(fn, null, action);
      }
      return tools.asyncOpt(fn, err, null);
    });
  };

  mod.get = function(project, type, fn) {
    client.lrange('projects:' + project + ':' + type, -cfg.ACTIONS_BUFFER_SIZE, -1, function(err, array) {
      if(!err && array) {
        var actions = [];
        return tools.asyncParallel(array, function(left, aid) {
          client.hgetall('actions:' + aid, function(err, action) {
            if(err) {
              return tools.asyncOpt(fn, err, []);
            }
            actions.push(action);
            return tools.asyncDone(left, function() {
              return tools.asyncOpt(fn, null, actions);
            });
          });
        });
      }
    });
  };

  return mod;

};
