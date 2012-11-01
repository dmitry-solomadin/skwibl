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

  mod.add = function(owner, pid, name, fn) {
    return client.incr('files:next', function(err, val) {
      if(!err) {
        var file = {
          id: val + ''
        , name: name
        , owner: owner
        , project: pid
        }

        client.hmset('files:' + val, file);
        client.sadd('project:' + pid + ':files', val);
        return tools.asyncOpt(fn, null, file);
      }
      return tools.asyncOpt(fn, err, null);
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
