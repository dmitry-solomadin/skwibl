/******************************************
 *           FRIENDS MANAGEMENT           *
 ******************************************/


/**
 * Module dependencies.
 */

var ctrls = require('../controllers');

exports.configure = function(app, passport) {

  /*
  *  all user friends
  */
  app.get('/friends', ctrls.isAuth, ctrls.friends);

  /*
  * invite user to be friends
  */
  app.post('/friends/add', ctrls.isAuth, ctrls.addFriend);

  /*
  * invite friend with social network
  */
  app.post('/friends/invite', ctrls.isAuth, ctrls.inviteFriend);

  /*
  * invite friend by email
  */
  app.post('/friends/inviteemail', ctrls.isAuth,  ctrls.inviteEmailFriend);

  /*
  * invite friend by link
  */
  app.post('/friends/invitelink', ctrls.isAuth, ctrls.inviteLinkFriend);

  /*
  * delete user from friends
  */
  app.post('/friends/delete', ctrls.isAuth, ctrls.deleteFriend);

  /*
  * confirm friend invitation
  */
  app.post('/friends/confirm', ctrls.isAuth, ctrls.confirmFriend);

}
