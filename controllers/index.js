/******************************************
 *              CONTROLLERS               *
 ******************************************/


/**
 * Module dependencies.
 */

var fs = require('fs');

var module;

fs.readdirSync(__dirname).forEach(function(name){
  var len = name.length
    , ext = name.substring(len - 3, len)
    , isModule = name !== 'index.js' && ext === '.js';
  if(isModule) {
    var mod = require('./' + name)
      , dep = name.substring(0, len - 3);
    module[dep] = mod;
  }
});

module.exports = module;
