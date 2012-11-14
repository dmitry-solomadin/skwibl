/******************************************
 *             USER MANAGEMENT            *
 ******************************************/

/**
 * Module dependencies.
 */

var db = require('../db');

var tools = require('../tools');

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
exports.edit = function(req, res) {
  res.render('index',
    { template: "partials/edituser" }
  );
};

/*
 * POST
 * Update user profile info
 */
exports.update = function(req, res) {
  db.users.setProperties(req.params.id, req.body.user, function(err) {
    if (err) {
      req.flash('error', "Something wrong happened.");
      res.redirect('/users/' + req.params.id + '/edit');
    }

    if (req._passport && req._passport.session.user) {
      return db.users.findById(req.user.id, function (err, user) {
        req._passport.session.user = user;
        req.user = user;
        res.redirect('/users/' + req.params.id + '/edit');
      });
    }

    res.redirect('/users/' + req.params.id + '/edit');
  });
};

/*
 * POST
 * Delete user profile
 */
exports.delete = function(req, res) {
  db.users.delete(req.user.id, function(err) {
    if(err) {
      req.flash('error', err);
      return res.redirect('/');
    }
    req.flash('error', 'Your profile has been successfuly deleted.');
    return res.redirect('/');
  });
};
