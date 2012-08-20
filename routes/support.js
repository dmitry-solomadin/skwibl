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



  /******************************************
  *             USER MANAGEMENT            *
  ******************************************/

  /*
  * get user profile
  */
  app.get('/users/:id', ctrls.isAuth, ctrls.users);

  /*
  * edit user personal information
  */
  app.get('/users/:id/edit', ctrls.isAuth, ctrls.editUser);

  /*
  * update user personal information
  */
  app.post('/users/update', ctrls.isAuth, ctrls.updateUser);

  /*
  * delete user
  */
  app.post('/users/delete', ctrls.isAuth, ctrls.deleteUser);

}
