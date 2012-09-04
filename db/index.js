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
  'auth'
// , 'files'
, 'contacts'
, 'mid'
, 'projects'
// , 'search'
, 'sessions'
// , 'support'
, 'users'
];

for(var i = 0, len = deps.length; i < len; i++) {
  var dep = deps[i]
    , mod = require('./' + dep)
    , obj = mod.setUp(client, this);
  this[dep] = obj;
}

module.exports = this;
