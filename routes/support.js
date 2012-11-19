/******************************************
 *             SUPPORT PAGES              *
 ******************************************/


/**
 * Module dependencies.
 */

var ctrls = require('../controllers');

exports.configure = function(app, passport) {

 /*
  * get tour page
  */
  app.get('/tour/:chapter?', ctrls.tour);

 /*
  * post mail for password recovery
  */
  app.post('/forgotpassword', ctrls.support.passwordRecovery);

 /*
  * check mail
  */
  app.get('/checkmail', ctrls.support.checkMail);

}
