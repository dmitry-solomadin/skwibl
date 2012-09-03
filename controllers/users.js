/******************************************
 *             USER MANAGEMENT            *
 ******************************************/

/**
 * Module dependencies.
 */

var db = require('../db');

/*
 * GET
 * Redirect to user profile
 */
exports.profile = function(req, res) {
  res.render('partials/user', { menu: 1 });
};

/*
 * GET
 * Edit personal profile
 */
exports.editUser = function(req, res) {
  res.render('partials/edituser', { menu: 1});
};

/*
 * POST
 * Update user profile info
 */
exports.updateUser = function(req, res) {
  db.setUserProperties(req.user.id, req.body.properties, function(err) {
    if(err) {
      return res.send(false);
    }
    return res.send(true);
  });
};

/*
 * POST
 * Delete user profile
 */
exports.deleteUser = function(req, res) {
  db.delUser(req.user.id, function(err) {
    if(err) {
      req.flash('error', err);
      return res.redirect('/');
    }
    req.flash('warning', 'Your profile has been successfuly deleted.');
    return res.redirect('/');
  });
};
