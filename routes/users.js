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
  app.get('/users/:id', ctrls.users.profile);

 /*
  * edit user personal information
  */
  app.get('/users/:id/edit', ctrls.mid.isAuth, ctrls.mid.isCurrentUser, ctrls.users.edit);

 /*
  * update user personal information
  */
  app.post('/users/:id/update', ctrls.mid.isAuth, ctrls.mid.isCurrentUser, ctrls.users.update);

 /*
  * delete user
  */
  app.post('/users/delete', ctrls.mid.isAuth, ctrls.users.delete);

}
