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
  res.render('partials/user', { articles: db.articles, menu: 1});
};

/*
 * GET
 * Edit personal profile
 */
exports.editUser = function(req, res) {
  res.render('partials/edituser', { menu: 1});
};
