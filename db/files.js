/******************************************
 *            FILES MANAGEMENT            *
 ******************************************/


/**
 * Module dependencies.
 */

var _ = require('underscore');

var tools = require('../tools');

exports.setUp = function(client, db) {

  var mod = {};

  mod.add = function(owner, cid, pid, name, mime, fn) {
    return client.incr('files:next', function(err, val) {
      if(!err) {
        if(cid) {
          var file = {
            elementId: val
          , name: name
          , mime: mime
          , owner: owner
          };
          client.hmset('files:' + val, file);
          db.canvases.setProperties('canvases:' + cid, {
            file: val
          });
          client.sadd('projects:' + pid + ':files', val);
          return tools.asyncOpt(fn, null, {
            canvasId: cid
          , element: file
          });
        }
        client.incr('canvases:next', function(err, cid) {
          if(!err) {
            var file = {
              elementId: val
            , name: name
            , mime: mime
            , owner: owner
            };
            client.hmset('files:' + val, file);
            client.sadd('projects:' + pid + ':files', val);
            var time;
            if(tools.getFileType(mime) === 'video') {
              time = 0;//file beginning
            }
            db.canvases.add(pid, val, time);
            return tools.asyncOpt(fn, null, {
              canvasId: cid
            , element: file
            });
          }
          return tools.asyncOpt(fn, err, null);
        });
      }
      return tools.asyncOpt(fn, err, null);
    });
  };

  mod.get = function(uid, fn) {
    //TODO
  };

  mod.project = function(pid, fn) {
    //TODO
  };

  mod.file = function(fid, fn) {
    client.hgetall('files:' + fid, function(err, file) {
      if(!err) {
        return tools.asyncOpt(fn, null, file);
      }
      return tools.asyncOpt(fn, err);
    });
  };

  mod.delete = function(id, fn) {
    //TODO
  };

  mod.findById = function(id, fn) {
    //TODO
  };

  mod.setProperties = function(id, properties, fn) {
    //TODO
  };

  return mod;

};
