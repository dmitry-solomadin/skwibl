/******************************************
 *          MIDDLEWARE FUNCTIONS          *
 ******************************************/


/**
 * Module dependencies.
 */

var tools = require('../tools');

exports.setUp = function(client, db) {

  var mod = {};

  mod.isMember = function(id, pid, fn) {
    client.sismember('projects:' + pid + ':users', id, fn);
  };

  mod.isFileInProject = function(fid, pid, fn) {
    client.sismember('projects:' + pid + ':files', fid, fn);
  };

  mod.isOwner = function(id, pid, fn) {
    client.hget('projects:' + pid, 'owner', function(err, val) {
      if(!err && val === id) {
        return tools.asyncOpt(fn, null, true);
      }
      return tools.asyncOpt(fn, err, false);
    });
  };

  mod.isInvited = function(id, aid, fn) {
    client.hget('activities:' + aid, 'owner', function(err, val) {
      if(!err && val === id) {
        return tools.asyncOpt(fn, null, true);
      }
      return tools.asyncOpt(fn, err, false);
    });
  };

  return mod;

};
