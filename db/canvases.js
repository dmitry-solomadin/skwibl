/******************************************
 *          CANVASES MANAGEMENT           *
 ******************************************/


/**
 * Module dependencies.
 */

var _ = require('underscore');

var tools = require('../tools');

exports.setUp = function(client, db) {

  var mod = {};

  mod.add = function(pid, fid, time, fn) {
    client.incr('canvases:next', function(err, val) {
      if(!err) {
        var canvas = {
          id: val
        , project: pid
        }
        if(fid) {
          canvas.file = fid;
        }
        if(time) {
          canvas.time = time;
        }
        client.hmset('canvases:' + val, canvas);
        client.sadd('projects:' + pid + ':canvases', val);
        return tools.asyncOpt(fn, null, canvas);
      }
      return tools.asyncOpt(fn, err, null);
    });
  };

  mod.get = function(cid, fn) {
    client.hgetall('canvases:' + cid, fn);
  };

  mod.index = function(pid, fn) {
    client.smembers('projects:' + pid + ':canvases', function(err, array) {
      if(!err && array && array.length) {
        var canvases = [];
        return tools.asyncParallel(array, function(left, cid) {
          db.canvases.get(cid, function(err, canvas) {
            if(!err && canvas) {
              db.files.file(canvas.file, function(err, file) {
                db.actions.getElements(cid, function(err, elements) {
                  if(!err) {
                    canvases.push({
                      canvasId: cid
                    , file: file
                    , elements: elements
                    });
                  }
                  return tools.asyncDone(left, function() {
                    return tools.asyncOpt(fn, null, canvases);
                  });
                });
              });
            }
          });
        });
      }
      return tools.asyncOpt(fn, err, []);
    });
  };

  mod.setProperties = function(cid, properties, fn) {
    client.hmset('canvases:' + cid, properties, fn);
  };

}
