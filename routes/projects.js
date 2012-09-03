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
  app.get('/projects', ctrls.isAuth, ctrls.projects);

 /*
  * enter project
  */
  app.get('/projects/:pid', ctrls.isAuth, ctrls.isMember, ctrls.project);

 /*
  * add new project
  */
  app.post('/projects/add', ctrls.isAuth, ctrls.addProject);

 /*
  * close project
  */
  app.post('/projects/close', ctrls.isAuth, ctrls.isMember, ctrls.closeProject);

 /*
  * reopen project
  */
  app.post('/projects/reopen', ctrls.isAuth, ctrls.isMember, ctrls.reopenProject);

 /*
  * delete project
  */
  app.post('/projects/delete', ctrls.isAuth, ctrls.isOwner, ctrls.deleteProject);

 /*
  * invite user to a project
  */
  app.post('/projects/invite', ctrls.isAuth, ctrls.isMember, ctrls.inviteProject);

  /*
   * invite user from social network to a project
   */
  app.post('/projects/invitesocial', ctrls.isAuth, ctrls.isMember, ctrls.inviteSocialProject);

 /*
  * invite user to a project by email
  */
  app.post('/projects/inviteemail', ctrls.isAuth, ctrls.isMember, ctrls.inviteEmailProject);

//  /*
//   * invite user to a project by link
//   */
//   app.post('/projects/invitelink', ctrls.isAuth, ctrls.isMember, ctrls.inviteLinkProject);

  /*
   * confirm user invitation
   */
  app.post('/projects/confirm', ctrls.isAuth, ctrls.isInvited, ctrls.comfirmProject);

  /*
   * remove user from a project
   */
  app.post('/project/remove', ctrls.isAuth, ctrls.isOwner, ctrls.removeFromProject);

}
