/******************************************
 *                 ROUTES                 *
 ******************************************/


/**
 * Module dependencies.
 */

var fs = require('fs');

exports.configure = function(app, passport) {
  fs.readdirSync(__dirname).forEach(function(name){
    var len = name.length
      , ext = name.substring(len - 3, len)
      , isModule = name !== 'index.js' && ext === '.js';
    if(isModule) {
      var mod = require('./' + name);
      mod.configure(app, passport);
    }
  });
};
