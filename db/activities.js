/******************************************
 *              ACTIVITIES                *
 ******************************************/


/**
 * Module dependencies.
 */

var tools = require('../tools')
  , cfg = require('../config')
  , announce = require('socket.io-announce')({ namespace: '/activities' });

exports.setUp = function (client, db) {

  var mod = {};

  mod.add = function (project, owner, type, invitingUserId, fn) {
    client.incr('activities:next', function (err, val) {
      if (!err) {
        var activity = {};
        activity.id = val;
        activity.project = project;
        activity.owner = owner;
        activity.type = type;
        activity.time = new Date().getTime();
        activity.status = 'new';
        activity.inviting = invitingUserId;
        client.hmset('activities:' + val, activity);
        client.rpush('users:' + owner + ':activities', val);

        announce.in("activities" + owner).emit('new');
        return tools.asyncOpt(fn, null, activity);
      }
      return tools.asyncOpt(fn, err, null);
    });
  };

  mod.getAllNew = function (id, fn) {
    mod.get(id, fn, function (activity) {
      return activity.status == "new";
    })
  };

  mod.get = function (id, fn, filter) {
    client.lrange('users:' + id + ':activities', -cfg.ACTIONS_BUFFER_SIZE, -1, function (err, array) {
      if (!err && array && array.length) {
        var activities = [];
        return tools.asyncParallel(array, function (left, aid) {
          return client.hgetall('activities:' + aid, function (err, activity) {
            if (err) {
              return tools.asyncOpt(fn, err, []);
            }

            if (filter) {
              if (filter(activity)) {
                activities.push(activity);
              }
            } else {
              activities.push(activity);
            }

            return tools.asyncDone(left, function () {
              return tools.asyncOpt(fn, null, activities);
            });
          });
        });
      }
      return tools.asyncOpt(fn, err, []);
    });
  };

  mod.getDataActivity = function (aid, done) {
    return client.hgetall('activities:' + aid, function (err, activity) {
      if (err) {
        return tools.asyncOpt(done, err, []);
      }

      var activities = [];
      activities.push(activity);
      mod.getDataActivities(activities, function (err) {
        done(err, activity);
      });
    });
  };

  mod.getDataActivities = function (activities, done) {
    return mod.getProjectForActivities(activities, function (err) {
      if (!err) {
        return mod.getUserForActivities(activities, function (err) {
          done(err);
        })
      }

      return done(err);
    })
  };

  mod.getProjectForActivities = function (activities, done) {
    return tools.asyncParallel(activities, function (left, activity) {
      return db.projects.getData(activity.project, function (err, project) {
        if (!err && project) {
          activity.project = project;
          return tools.asyncDone(left, function () {
            return tools.asyncOpt(function () {
              done();
            }, null, null);
          });
        }

        return tools.asyncOpt(function () {
          done(err);
        }, err, []);
      });
    });
  };

  mod.getUserForActivities = function (activities, done) {
    return tools.asyncParallel(activities, function (left, activity) {
      return db.users.findById(activity.inviting, function (err, user) {
        if (!err && user) {
          activity.inviting = user;
          return tools.asyncDone(left, function () {
            return tools.asyncOpt(function () {
              done();
            }, null, null);
          });
        }

        return tools.asyncOpt(function () {
          done(err);
        }, err, []);
      });
    });
  };

  return mod;

};
