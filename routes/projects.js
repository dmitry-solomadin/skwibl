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
  app.get('/projects/:id', ctrls.isAuth, ctrls.isMember, ctrls.project);

  /*
  * add new project
  */
  app.post('/projects/add', ctrls.isAuth, ctrls.addProject);

  /*
  * invite user to a project
  */
  app.post('/projects/invite', ctrls.isAuth, ctrls.inviteProject);

  /*
  * invite user to a project by email
  */
  app.post('/projects/inviteemail', ctrls.isAuth, ctrls.inviteEmailProject);

  /*
  * invite user to a project by link
  */
  app.post('/projects/invitelink', ctrls.isAuth, ctrls.inviteLinkProject);

  /*
  * delete project
  */
  app.post('/projects/delete', ctrls.isAuth, ctrls.deleteProject);

}
