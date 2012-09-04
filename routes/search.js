/******************************************
 *                 SEARCH                 *
 ******************************************/


/**
 * Module dependencies.
 */

var ctrls = require('../controllers');

exports.configure = function(app, passport) {

  /*
  * search video, photo, users
  */
  app.get('/search', ctrls.mid.isAuth, ctrls.search.search);

}
