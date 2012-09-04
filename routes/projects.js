/******************************************
 *           PROJECTS MANAGEMENT          *
 ******************************************/


/**
 * Module dependencies.
 */

var ctrls = require('../controllers');

exports.configure = function(app, passport) {

 /*
  * get project list
  */
  app.get('/projects', ctrls.mid.isAuth, ctrls.projects.get);

 /*
  * enter project
  */
  app.get('/projects/:pid', ctrls.mid.isAuth, ctrls.mid.isMember, ctrls.projects.show);

 /*
  * add new project
  */
  app.post('/projects/create', ctrls.mid.isAuth, ctrls.projects.create);

 /*
  * close project
  */
  app.post('/projects/close', ctrls.mid.isAuth, ctrls.mid.isMember, ctrls.projects.close);

 /*
  * reopen project
  */
  app.post('/projects/reopen', ctrls.mid.isAuth, ctrls.mid.isMember, ctrls.projects.reopen);

 /*
  * delete project
  */
  app.post('/projects/delete', ctrls.mid.isAuth, ctrls.mid.isOwner, ctrls.projects.delete);

 /*
  * invite user to a project
  */
  app.post('/projects/invite', ctrls.mid.isAuth, ctrls.mid.isMember, ctrls.projects.invite);

  /*
   * invite user from social network to a project
   */
  app.post('/projects/invitesocial', ctrls.mid.isAuth, ctrls.mid.isMember, ctrls.projects.inviteSocial);

 /*
  * invite user to a project by email
  */
  app.post('/projects/inviteemail', ctrls.mid.isAuth, ctrls.mid.isMember, ctrls.projects.inviteEmail);

//  /*
//   * invite user to a project by link
//   */
//   app.post('/projects/invitelink', ctrls.mid.isAuth, ctrls.mid.isMember, ctrls.projects.inviteLink);

  /*
   * confirm user invitation
   */
  app.post('/projects/confirm', ctrls.mid.isAuth, ctrls.mid.isInvited, ctrls.projects.confirm);

  /*
   * remove user from a project
   */
  app.post('/project/remove', ctrls.mid.isAuth, ctrls.mid.isOwner, ctrls.projects.remove);

}
