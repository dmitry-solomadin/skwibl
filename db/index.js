/******************************************
 *                  DB                    *
 ******************************************/


//TODO Delete
exports.articles  = {
  '1':{'name':'alex', 'avatar' : '/public/images/avatar.png', 'id' : '15', 'content':'The day started to the upside, after big names like Goldman Sachs, Coca-Cola and Johnson & Johnson beat the Street’s consensus earnings view, but the market pulled back after Federal Reserve Chairman Ben Bernanke played it straight during his semiannual monetary policy report to the Senate Banking Committee.'},
  '2':{'name':'Boris', 'avatar' : '/public/images/avatar.png', 'id' : '15', 'content':'The day started to the upside, after big names like Goldman Sachs, Coca-Cola and Johnson & Johnson beat the Street’s consensus earnings view, but the market pulled back after Federal Reserve Chairman Ben Bernanke played it straight during his semiannual monetary policy report to the Senate Banking Committee.'}
};

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
, 'friends'
, 'login'
, 'middleware'
, 'rooms'
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
