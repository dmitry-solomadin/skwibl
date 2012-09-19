/******************************************
 *                SOCKETS                 *
 ******************************************/


/**
 * Module dependencies.
 */

var tools = require('../tools');

exports.configure = function(sio) {
  tools.include(__dirname, function(mod, name) {
    mod.configure(sio);
  });
};
