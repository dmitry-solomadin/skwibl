/******************************************
 *             FILE MANAGEMENT            *
 ******************************************/


/**
 * Module dependencies.
 */

var ctrls = require('../controllers');

exports.configure = function(app, passport) {

  app.get('/dev/player', ctrls.isAuth, ctrls.player);

  app.get('/dev/room', ctrls.isAuth, ctrls.room);

};
