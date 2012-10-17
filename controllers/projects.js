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
      return db.activities.get(req.user.id, function(err, activities) {
        if(!err) {
          return res.render('projects/index', {
              projects: projects
            , activities: activities
          });
        }
        return next(err);
      });
    }
    return next(err);
  });
};

/*
 * GET
 * Enter the project
 */
exports.show = function(req, res, next) {
  db.projects.set(req.user.id, req.params.pid, function () {
    db.projects.getData(req.params.pid, req.user.id, function (err, projects) {
      if (!err) {
        return res.render('index', {
          template: "projects/show",
          user: req.user,
          projects: projects
        });
      }
      return next(err);
    });
  });
};

/*
 * POST
 * Add new project
 */
exports.add = function(req, res) {
  if(!req.body.name || req.body.name === '') {
    return res.send(false);
  }
  db.projects.add(req.user.id, req.body.name, function(err, project) {
    if(!err) {
      return res.send(project);
    }
    return res.send(false);
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
  db.projects.delete(req.body.pid, function(err) {
    tools.returnStatus(err, res);
  });
};

/*
 * POST
 * Invite user to a project
 */
exports.invite = function(req, res) {
  var data = req.body;
  db.projects.invite(data.pid, req.user.id, data.uid, function(err) {
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
  var data = req.body;
  db.projects.confirm(data.aid, req.user.id, data.answer, function(err) {
    tools.returnStatus(err, res);
  });
};

/*
 * POST
 * Remove user from a project
 */
exports.remove = function(req, res) {
  var data = req.body;
  if(req.user.id !== data.id) {
    return db.projects.remove(data.pid, data.id, function(err) {
      tools.returnStatus(err, res);
    });
  }
  return res.send(false);
};
