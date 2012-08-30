/******************************************
 *             FILE MANAGEMENT            *
 ******************************************/


/**
 * Module dependencies.
 */

var ctrls = require('../controllers');

exports.configure = function(app, passport) {

  app.get('/dev/player', ctrls.isAuth, ctrls.devPlayer);

}
