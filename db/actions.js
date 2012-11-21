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

  mod.update = function(project, owner, type, data, fn) {
    var aid = data.element.elementId
      , action = {};
    action.project = project;
    action.owner = owner;
    action.type = type;
    if(data.element.canvasId) {
      action.canvas = canvasId;
    }
    if(data.comment) {
      actions.comment = true;
    }
    action.time = new Date;
    action.data = data.element;
    client.hmset('actions:' + aid, action);
    client.rpush('projects:' + project + ':' + type, val);
    return tools.asyncOpt(fn, null, action);
  };

  mod.delete = function(aid, fn) {
    client.del('actions:' + aid, fn);
  };

  mod.get = function(project, type, fn) {
    client.lrange('projects:' + project + ':' + type, -cfg.ACTIONS_BUFFER_SIZE, -1, function(err, array) {
      if(!err && array && array.length) {
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

  mod.getCanvas = function(cid, type, fn) {
    client.lrange('projects:' + cid + ':' + type, 0, -1, function(err, array) {
      if(!err && array && array.length) {
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

  mod.getElements = function(cid, fn) {
    client.lrange('projects:' + cid + ':elements', 0, -1, function(err, array) {
      if(!err && array && array.length) {
        var actions = [];
        return tools.asyncParallel(array, function(left, aid) {
          client.hgetall('actions:' + aid, function(err, action) {
            if(err) {
              return tools.asyncOpt(fn, err, []);
            }
            if(action.comment) {
              //TODO get comment texts
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

  mod.getComments = function(eid, fn) {
    client.lrange("comments:" + eid + ":texts", 0, -1, function(err, array) {
      if(!err && array && array.length) {
        var comments = [];
        return client.mget(array.map(tools.commentText), fn);
      }
    });
  };

  mod.updateComment = function(data, fn) {
    client.set("texts:" + data.elementId, data.text);
    client.rpush('comments:' + data.commentId + ':texts', data.elementId);
    return tools.asyncOpt(fn, null, data);
  };

  return mod;

};
