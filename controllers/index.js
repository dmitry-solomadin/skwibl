/******************************************
 *              CONTROLLERS               *
 ******************************************/

var deps = [
  'auth'
, 'aux'
, 'files'
, 'contacts'
, 'mid'
, 'projects'
, 'search'
, 'support'
, 'users'
, 'dev'
];

for(var i = 0, len = deps.length; i < len; i++) {
  var dep = deps[i]
    , mod = require('./' + dep);
  this[dep] = mod;
}

module.exports = this;
