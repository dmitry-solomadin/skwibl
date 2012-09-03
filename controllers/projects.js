/******************************************
 *           PROJECTS MANAGEMENT          *
 ******************************************/


/**
 * Module dependencies.
 */

var db = require('../db');

/*
 * GET
 * Get all projects
 */
exports.projects = function(req, res, next) {
  db.getUserProjects(req.user.id, function(err, projects) {
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
exports.project = function(req, res, next) {
  db.getProjectData(req.params.pid, req.user.id, function(err, projects) {
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
exports.addProject = function(req, res) {
  db.addProject(req.user.id, req.body.name, function(err, project) {
    if(!err) {
      return res.send(true);
    }
    res.send(false);
  });
};

/*
 * POST
 * Close project
 */
exports.closeProject = function(req, res) {
  db.setProjectProperties(req.body.pid, {
    status: 'closed'
  , end: new Date
  }, function(err) {
    if(!err) {
      return res.send(true);
    }
    res.send(false);
  });
};

/*
 * POST
 * Reopen project
 */
exports.reopenProject = function(req, res) {
  db.setProjectProperties(req.body.pid, {
    status: 'reopened'
  }, function(err) {
    if(!err) {
      return res.send(true);
    }
    res.send(false);
  });
};

/*
 * POST
 * Delete project
 */
exports.deleteProject = function(req, res) {
  db.setProjectProperties(req.body.pid, {
    status: 'deleted'
  }, function(err) {
    if(!err) {
      return res.send(true);
    }
    res.send(false);
  });
};

/*
 * POST
 * Invite user to a project
 */
exports.inviteProject = function(req, res) {
  var data = req.body;
  db.inviteUserToProject(data.pid, data.id, function(err) {
    if(!err) {
      return res.send(true);
    }
    res.send(false);
  });
};

/*
 * POST
 * Invite user to a project from social network
 */
exports.inviteSocialProject = function(req, res) {
  var data = req.body;
  db.inviteSocialUserToProject(data.pid, data.provider, data.providerId, function(err) {
    if(!err) {
      return res.send(true);
    }
    res.send(false);
  });
};

/*
 * POST
 * Invite user to project by email
 */
exports.inviteEmailProject = function(req, res) {
  var data = req.body;
  db.inviteEmailUserToProject(data.pid, data.email, function(err) {
    if(!err) {
      return res.send(true);
    }
    res.send(false);
  });
}

/*
 * POST
 * Invite user to a project by link
 */
exports.inviteLinkProject = function(req, res) {
  db.inviteLinkUserToProject(req.body.pid, function(err) {
    if(!err) {
      return res.send(true);
    }
    res.send(false);
  });
};

/*
 * POST
 * Confirm user invitation to a project
 */
exports.confirmProject = function(req, res) {
  db.confirmUserToProject(req.user.id, req.body.pid, function(err) {
    if(!err) {
      return res.send(true);
    }
    res.send(false);
  });
};

/*
 * POST
 * Remove user to a project
 */
exports.removeFromProject = function(req, res) {
  var data = req.body;
  db.removeUserFromProject(data.pid, data.id, function(err) {
    if(!err) {
      return res.send(true);
    }
    res.send(false);
  });
};
