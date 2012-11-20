var ctrls = require('../controllers');

exports.configure = function(app, passport) {

  app.get('/projects', ctrls.mid.isAuth, ctrls.projects.index);

  app.get('/projects/new', ctrls.mid.isAuth, ctrls.projects.new);

  app.get('/projects/:pid', ctrls.mid.isAuth, ctrls.mid.isMember, ctrls.projects.show);

  app.get('/projects/:pid/participants', ctrls.mid.isAuth, ctrls.mid.isMember, ctrls.projects.participants);

  app.post('/projects/add', ctrls.mid.isAuth, ctrls.projects.add);

  app.post('/projects/close', ctrls.mid.isAuth, ctrls.mid.isMember, ctrls.projects.close);

  app.post('/projects/reopen', ctrls.mid.isAuth, ctrls.mid.isMember, ctrls.projects.reopen);

  app.post('/projects/delete', ctrls.mid.isAuth, ctrls.mid.isOwner, ctrls.projects.delete);

  app.post('/projects/invite', ctrls.mid.isAuth, ctrls.mid.isMember, ctrls.projects.invite);

  app.post('/projects/invitesocial', ctrls.mid.isAuth, ctrls.mid.isMember, ctrls.projects.inviteSocial);

//  /*
//   * invite user to a project by link
//   */
//   app.post('/projects/invitelink', ctrls.mid.isAuth, ctrls.mid.isMember, ctrls.projects.inviteLink);

  app.post('/projects/confirm', ctrls.mid.isAuth, ctrls.mid.isInvited, ctrls.projects.confirm);

  app.post('/projects/remove', ctrls.mid.isAuth, ctrls.mid.isOwner, ctrls.projects.remove);

};
