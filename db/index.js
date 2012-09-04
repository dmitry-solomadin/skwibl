/******************************************
 *                  DB                    *
 ******************************************/

/**
 * Module dependencies.
 */

var fs = require('fs')
  , redis = require('redis');

var module
  , client = redis.createClient();

client.on("error", function (err) {
  console.log("Error " + err);
});

fs.readdirSync(__dirname).forEach(function(name){
  var len = name.length
    , ext = name.substring(len - 3, len)
    , isModule = name !== 'index.js' && ext === '.js';
  if(isModule) {
    var mod = require('./' + name)
      , dep = name.substring(0, len - 3)
      , obj = mod.setUp(client, module);
    module[dep] = obj;
  }
});

module.exports = module;
