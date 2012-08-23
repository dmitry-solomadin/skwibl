/******************************************
 *             SUPPORT PAGES              *
 ******************************************/


/**
 * Module dependencies.
 */

var ctrls = require('../controllers');

exports.configure = function(app, passport) {

  /*
  * restore user password
  */
  app.get('/forgotpassword', ctrls.forgotPassword);

  /*
  * post mail for password recovery
  */
  app.post('/forgotpassword', ctrls.passwordRecovery);

  /*
  * check mail
  */
  app.get('/checkmail', ctrls.checkMail);

}
