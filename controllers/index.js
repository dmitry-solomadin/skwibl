/******************************************
 *              CONTROLLERS               *
 ******************************************/


/**
 * Module dependencies.
 */

var tools = require('../tools');

var module;

tools.include(__dirname, function(mod, name) {
  module[name] = mod;
});

module.exports = module;
