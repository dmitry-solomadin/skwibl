/******************************************
 *            DEVELOPMENT PAGES            *
 ******************************************/


/**
 * Module dependencies.
 */

var ctrls = require('../controllers');

exports.configure = function(app, passport) {

  app.get('/dev/player', ctrls.mid.isAuth, ctrls.dev.player);

  app.get('/dev/room', ctrls.mid.isAuth, ctrls.dev.room);

};
