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
  res.redirect('/users/' + req.user.id);
};

/*
 * GET
 * Get user profile
 */
exports.users = function(req, res) {
  res.render('index', {'articles' : db.articles, title: req.params.id, title: req.params.id, template: 'user' , menu: 1 });
};

/*
 * GET
 * Edit personal profile
 */
exports.editUser = function(req, res) {
  res.render('index', { title: req.params.id, template: 'edituser' , menu: 1});
};
