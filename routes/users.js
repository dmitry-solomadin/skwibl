/******************************************
 *             USER MANAGEMENT            *
 ******************************************/


/**
 * Module dependencies.
 */

var ctrls = require('../controllers');

exports.configure = function(app, passport) {

  /*
   * get user profile
   */
  app.get('/users/:id', ctrls.isAuth, ctrls.profile);

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
