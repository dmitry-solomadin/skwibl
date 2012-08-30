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
 * GET
 * Check if the user is the project member
 */
exports.isMember = function(req, res, next) {
  db.isUserProjectMember(req.user.id, req.params.id, function(err, val) {
    if(val) {
      return next();
    }
    return res.redirect('back');
  });
};
