/******************************************
 *                  DB                    *
 ******************************************/

/**
 * Module dependencies.
 */

var redis = require('redis');

var tools = require('../tools');

var module
  , client = redis.createClient();

client.on("error", function (err) {
  console.log("Error " + err);
});

tools.include(__dirname, function(mod, name) {
  var obj = mod.setUp(client, module);
  module[name] = obj;
});

module.exports = module;
