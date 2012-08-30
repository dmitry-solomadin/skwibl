/******************************************
 *              CONTROLLERS               *
 ******************************************/

var deps = [
  'auxiliary'
, 'files'
, 'contacts'
, 'login'
, 'middleware'
, 'projects'
, 'search'
, 'support'
, 'users'
, 'dev'
];

for(var i = 0, len = deps.length; i < len; i++) {
  var mod = require('./' + deps[i]);
  for(var p in mod) {
    this[p] = mod[p];
  }
}

module.exports = this;
