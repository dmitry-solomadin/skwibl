/******************************************
 *           PROJECTS MANAGEMENT          *
 ******************************************/


/**
 * Module dependencies.
 */

var db = require('../db');

var tools = require('../tools');

/*
 * GET
 * Get all projects
 */
exports.get = function(req, res, next) {
  db.projects.get(req.user.id, function(err, projects) {
    if(!err) {
      return res.render('index', { title: req.params.id, template: 'projects' , menu: 3});
    }
    return next(err);
  });
};

/*
 * GET
 * Enter the project
 */
exports.show = function(req, res, next) {
  db.projects.getData(req.params.pid, req.user.id, function(err, projects) {
    if(!err) {
      return res.render('index', { title: req.params.pid, template: 'project' , menu: 3});
    }
    return next(err);
  });
};

/*
 * POST
 * Add new project
 */
exports.create = function(req, res) {
  db.projects.add(req.user.id, req.body.name, function(err, project) {
    tools.returnStatus(err, res);
  });
};

/*
 * POST
 * Close project
 */
exports.close = function(req, res) {
  db.projects.setProperties(req.body.pid, {
    status: 'closed'
  , end: new Date
  }, function(err) {
    tools.returnStatus(err, res);
  });
};

/*
 * POST
 * Reopen project
 */
exports.reopen = function(req, res) {
  db.projects.setProperties(req.body.pid, {
    status: 'reopened'
  }, function(err) {
    tools.returnStatus(err, res);
  });
};

/*
 * POST
 * Delete project
 */
exports.delete = function(req, res) {
  db.projects.setProperties(req.body.pid, {
    status: 'deleted'
  }, function(err) {
    tools.returnStatus(err, res);
  });
};

/*
 * POST
 * Invite user to a project
 */
exports.invite = function(req, res) {
  var data = req.body;
  db.projects.invite(data.pid, data.id, function(err) {
    tools.returnStatus(err, res);
  });
};

/*
 * POST
 * Invite user to a project from social network
 */
exports.inviteSocial = function(req, res) {
  var data = req.body;
  db.projects.inviteSocial(data.pid, data.provider, data.providerId, function(err) {
    tools.returnStatus(err, res);
  });
};

/*
 * POST
 * Invite user to project by email
 */
exports.inviteEmail = function(req, res) {
  var data = req.body;
  db.projects.inviteEmail(data.pid, data.email, function(err) {
    tools.returnStatus(err, res);
  });
}

/*
 * POST
 * Invite user to a project by link
 */
exports.inviteLink = function(req, res) {
  db.projects.inviteLink(req.body.pid, function(err) {
    tools.returnStatus(err, res);
  });
};

/*
 * POST
 * Confirm user invitation to a project
 */
exports.confirm = function(req, res) {
  db.projects.confirm(req.user.id, req.body.pid, function(err) {
    tools.returnStatus(err, res);
  });
};

/*
 * POST
 * Remove user to a project
 */
exports.remove = function(req, res) {
  var data = req.body;
  db.projects.remove(data.pid, data.id, function(err) {
    tools.returnStatus(err, res);
  });
};
