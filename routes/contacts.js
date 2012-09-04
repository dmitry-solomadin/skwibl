/******************************************
 *           CONTACTS MANAGEMENT          *
 ******************************************/


/**
 * Module dependencies.
 */

var ctrls = require('../controllers');

exports.configure = function(app, passport) {

 /*
  *  all user contacts
  */
  app.get('/contacts', ctrls.mid.isAuth, ctrls.contacts.get);

}
