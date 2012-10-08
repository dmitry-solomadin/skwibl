/******************************************
 *            DEVELOPMENT PAGES           *
 ******************************************/


/**
 * Module dependencies.
 */

var ctrls = require('../controllers');

exports.configure = function(app, passport) {

  app.get('/dev/player', ctrls.mid.isAuth, ctrls.dev.player);

  app.get('/dev/room', ctrls.mid.isAuth, ctrls.dev.room);

  app.post('/dev/chat', ctrls.mid.isAuth, ctrls.dev.switchProject);

  app.get('/dev/projects', ctrls.mid.isAuth, ctrls.dev.projects);

  app.get('/dev/projects/:pid', ctrls.mid.isAuth, ctrls.dev.showProject);

  app.post('/dev/projects/get', ctrls.mid.isAuth, ctrls.mid.isMember, ctrls.dev.getProject);

};
