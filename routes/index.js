/******************************************
 *                 ROUTES                 *
 ******************************************/


/**
 * Module dependencies.
 */

var tools = require('../tools');

exports.configure = function(app, passport) {
  tools.include(__dirname, function(mod, name) {
    mod.configure(app, passport);
  });
};
