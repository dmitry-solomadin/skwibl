/******************************************
 *                 ROUTES                 *
 ******************************************/

var deps = [
  'files'
, 'friends'
, 'login'
, 'rooms'
, 'search'
, 'support'
];

exports.configure = function(app, passport) {
  for(var i = 0, len = deps.length; i < len; i++) {
    var mod = require('./' + deps[i]);
    mod.configure(app, passport);
  }
};
