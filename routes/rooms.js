/******************************************
 *             ROOM MANAGEMENT            *
 ******************************************/


/**
 * Module dependencies.
 */

var ctrls = require('../controllers');

exports.configure = function(app, passport) {

  /*
  * get room list
  */
  app.get('/rooms', ctrls.isAuth, ctrls.rooms);

  /*
  * enter room
  */
  app.get('/rooms/:id', ctrls.isAuth, ctrls.isMember, ctrls.room);

  /*
  * add new room
  */
  app.post('/rooms/add', ctrls.isAuth, ctrls.addRoom);

  /*
  * invite user to a room
  */
  app.post('/rooms/invite', ctrls.isAuth, ctrls.inviteRoom);

  /*
  * invite user to a room by email
  */
  app.post('/rooms/inviteemail', ctrls.isAuth, ctrls.inviteEmailRoom);

  /*
  * invite user to a room by link
  */
  app.post('/rooms/invitelink', ctrls.isAuth, ctrls.inviteLinkRoom);

  /*
  * delete room
  */
  app.post('/rooms/delete', ctrls.isAuth, ctrls.deleteRoom);

}
