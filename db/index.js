/******************************************
 *                  DB                    *
 ******************************************/

/**
 * Module dependencies.
 */

var redis = require('redis');

var client = redis.createClient();

client.on("error", function (err) {
  console.log("Error " + err);
});

var deps = [
  'auxiliary'
// , 'files'
, 'contacts'
, 'login'
, 'middleware'
, 'projects'
// , 'search'
// , 'support'
, 'users'
];

for(var i = 0, len = deps.length; i < len; i++) {
  var mod = require('./' + deps[i]);
  var obj = mod.setUp(client);
  for(var p in obj) {
    this[p] = obj[p];
  }
}

module.exports = this;
