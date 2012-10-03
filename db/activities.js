/******************************************
 *              ACTIVITIES                *
 ******************************************/


/**
 * Module dependencies.
 */

var tools = require('../tools')
  , cfg = require('../config');

exports.setUp = function(client, db) {

  var mod = {};

  mod.add = function(project, owner, type, data, fn) {
    client.incr('activities:next', function(err, val) {
      if(!err) {
        var activity = {};
        activity.id = val;
        activity.project = project;
        activity.owner = owner;
        activity.type = type;
        activity.time = new Date;
        activity.status = 'new';
        activity.data = data;
        client.hmset('activities:' + val, activity);
        client.rpush('users:' + owner + ':' + type, val);
        return tools.asyncOpt(fn, null, activity);
      }
      return tools.asyncOpt(fn, err, null);
    });
  };

  mod.get = function(id, fn) {
    client.lrange('users:' + id + ':activities', -cfg.ACTIONS_BUFFER_SIZE, -1, function(err, array) {
      if(!err && array && array.length) {
        var activities = [];
        return tools.asyncParallel(array, function(left, aid) {
          return client.hgetall('activities:' + aid, function(err, activity) {
            if(err) {
              return tools.asyncOpt(fn, err, []);
            }
            activities.push(activity);
            return tools.asyncDone(left, function() {
              return tools.asyncOpt(fn, null, activities);
            });
          });
        });
      }
      return tools.asyncOpt(fn, err, []);
    });
  };

  return mod;

};
