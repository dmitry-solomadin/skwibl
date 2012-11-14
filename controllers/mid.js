/******************************************
 *          MIDDLEWARE FUNCTIONS          *
 ******************************************/

/**
 * Module dependencies.
 */
var db = require('../db');

/*
 * ALL
 * Check authentication
 */
exports.isAuth = function(req, res, next) {
  if(req.isAuthenticated()) {
    return next();
  }
  if(req.method === 'GET') {
    return res.redirect('/');
  }
  return res.json({
    success: false
  , message: 'not authenticated'
  });
};

/*
 * ALL
 * Check that user id in params matches authenticated user id.
 */
exports.isCurrentUser = function(req, res, next) {
  if(req.user.id == req.params.id) {
    return next();
  }

  if(req.method === 'GET') {
    req.flash('error', "You can't view this page.");
    return res.redirect('/');
  }
  return res.json({
    success: false
    , message: 'not authenticated'
  });
};

/*
 * ALL
 * Check if the user is the project member
 */
exports.isMember = function(req, res, next) {
  var pid = req.params.pid || req.body.pid || req.query.pid;
  db.mid.isMember(req.user.id, pid, function(err, val) {
    if(val) {
      return next();
    }
    if(req.method === 'GET') {
      return res.redirect('back');
    }
    return res.json({
      success: false
    , message: 'not a member'
    });
  });
};

/*
 * All
 * Check if the file belongs to the project
 */
exports.isFileInProject = function(req, res, next) {
  var pid = req.params.pid || req.body.pid
      fid = req.params.fid || req.body.fid;
  db.mid.isFileInProject(fid, pid, function(err, val) {
    if(val) {
      return next();
    }
    if(req.method === 'GET') {
      return res.redirect('back');
    }
    return res.json({
      success: false
    , message: 'file doesn\'t belong to the project'
    });
  });
}

/*
 * POST
 * Check if the user is project owner
 */
exports.isOwner = function(req, res, next) {
  db.mid.isOwner(req.user.id, req.body.pid, function(err, val) {
    if(val) {
      return next();
    }
    return res.json({
      success: false
    , message: 'has no permission'
    });
  });
};

/*
 * POST
 * Check if the user is invited to a project
 */
exports.isInvited = function(req, res, next) {
  db.mid.isInvited(req.user.id, req.body.aid, function(err, val) {
    if(val) {
      return next();
    }
    return res.json({
      success: false
    , message: 'not invited'
    });
  });
};
