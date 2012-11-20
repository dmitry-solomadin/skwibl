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
exports.index = function (req, res, next) {
  db.projects.get(req.user.id, function (err, projects) {
    if (!err) {
      return res.render('index', {
        template:"projects/index",
        projects:projects
      });
    }
    return next(err);
  });
};

/*
 * GET
 * Enter the project
 */
exports.show = function (req, res, next) {
  db.projects.set(req.user.id, req.params.pid, function () {
    db.projects.getData(req.params.pid, function (err, project) {
      if (!err) {
        return res.render('index', {
          template:"projects/show",
          pid:req.params.pid,
          project:project
        });
      }
      return next(err);
    });
  });
};

/*
 * GET
 * Show new project page.
 */
exports.new = function (req, res) {
  return res.render('index', {
    template:"projects/new"
  });
};

/*
 * POST
 * Add new project
 */
exports.add = function (req, res) {
  if (!req.body.name || req.body.name === '') {
    tools.addError(req, "Please, enter project name.", "projectName");
    return res.redirect("/projects/new");
  }

  db.projects.add(req.user.id, req.body.name, function (err, project) {
    if (!err) {
      if (req.body.inviteeEmails) {
        return db.projects.inviteEmail(project.id, req.user.id, req.body.inviteeEmails, function (err, user) {
          if (err) {
            req.flash("warning", "Project was created but there was some problems with sending invites.");
          } else {
            req.flash("message", "Project was created invites were sent.");
          }

          return res.redirect("/projects");
        });
      }

      req.flash("message", "Project was created");
      return res.redirect("/projects");
    }

    return res.redirect("/projects/new");
  });
};

/*
 * POST
 * Close project
 */
exports.close = function (req, res) {
  db.projects.setProperties(req.body.pid, {
    status:'closed', end:new Date
  }, function (err) {
    tools.returnStatus(err, res);
  });
};

/*
 * POST
 * Reopen project
 */
exports.reopen = function (req, res) {
  db.projects.setProperties(req.body.pid, {
    status:'reopened'
  }, function (err) {
    tools.returnStatus(err, res);
  });
};

/*
 * POST
 * Delete project
 */
exports.delete = function (req, res) {
  db.projects.delete(req.body.pid, function (err) {
    tools.returnStatus(err, res);
  });
};

/*
 * POST
 * Invite user to a project
 */
exports.invite = function (req, res) {
  var data = req.body;
  db.projects.inviteEmail(data.pid, req.user.id, data.email, function (err, user) {
    if (err || !user) {
      return tools.sendError(res, err);
    }

    return db.users.persist(user, function () {
      db.projects.getData(data.pid, function (err, project) {
        if (!err) {
          return res.send(true);
        }

        return res.send(false);
      });
    });
  });
};

/*
 * GET
 * show project participants
 */
exports.participants = function (req, res) {
  db.projects.getData(req.params.pid, function (err, project) {
    if (!err) {
      return res.render("./projects/invite/participants.ect", {
        project: project
      })
    }
    res.send(false);
  });
};

/*
 * POST
 * Invite user to a project from social network
 */
exports.inviteSocial = function (req, res) {
  var data = req.body;
  db.projects.inviteSocial(data.pid, data.provider, data.providerId, function (err) {
    tools.returnStatus(err, res);
  });
};

/*
 * POST
 * Invite user to a project by link
 */
exports.inviteLink = function (req, res) {
  db.projects.inviteLink(req.body.pid, function (err) {
    tools.returnStatus(err, res);
  });
};

/*
 * POST
 * Confirm user invitation to a project
 */
exports.confirm = function (req, res) {
  var data = req.body;
  return db.projects.confirm(data.aid, req.user.id, data.answer, function (err) {
    if (err) {
      return res.send(true)
    }

    return db.activities.getDataActivity(data.aid, function (err, activity) {
      if (err) {
        return res.send(true)
      }

      return res.render("./activities/activity", {
        activity:activity
      });
    });
  });
};

/*
 * POST
 * Remove user from a project
 */
exports.remove = function (req, res) {
  var data = req.body;
  if (req.user.id !== data.id) {
    return db.projects.remove(data.pid, data.id, function (err) {
      if (err){
        return res.send(false);
      }

      return res.send({uid: data.id});
    });
  }
  return res.send(false);
};
