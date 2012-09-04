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
  * restore user password
  */
  app.get('/forgotpassword', ctrls.support.forgotPassword);

 /*
  * post mail for password recovery
  */
  app.post('/forgotpassword', ctrls.support.recoverPassword);

 /*
  * check mail
  */
  app.get('/checkmail', ctrls.support.checkMail);

}
