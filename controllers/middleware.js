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
 * Check if the user is the project member
 */
exports.isMember = function(req, res, next) {
  db.isUserProjectMember(req.user.id, req.params.pid, function(err, val) {
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
 * POST
 * Check if the user is project owner
 */
exports.isOwner = function(req, res, next) {
  db.isUserProjectOwner(req.user.id, req.body.pid, function(err, val) {
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
  db.isUserInvited(req.user.id, req.body.pid, function(err, val) {
    if(val) {
      return next();
    }
    return res.json({
      success: false
    , message: 'not invited'
    });
  });
};
