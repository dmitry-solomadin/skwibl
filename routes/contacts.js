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
  app.get('/contacts', ctrls.isAuth, ctrls.contacts);

 /*
  * invite user to be contacts
  */
  app.post('/contacts/add', ctrls.isAuth, ctrls.addContact);

 /*
  * invite contact with social network
  */
  app.post('/contacts/invite', ctrls.isAuth, ctrls.inviteContact);

 /*
  * invite contact by email
  */
  app.post('/contacts/inviteemail', ctrls.isAuth,  ctrls.inviteEmailContact);

 /*
  * invite contact by link
  */
  app.post('/contacts/invitelink', ctrls.isAuth, ctrls.inviteLinkContact);

 /*
  * delete user from contacts
  */
  app.post('/contacts/delete', ctrls.isAuth, ctrls.deleteContact);

 /*
  * confirm contact invitation
  */
  app.post('/contacts/confirm', ctrls.isAuth, ctrls.confirmContact);

}
