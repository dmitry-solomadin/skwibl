/******************************************
 *             SUPPORT PAGES              *
 ******************************************/

/**
 * Module dependencies.
 */

var db = require('../db')
  , smtp = require('../smtp');

/*
 * GET
 * Password recovery page
 */
exports.forgotPassword = function(req, res) {
  res.render('index', {
    template: 'users/forgot_password'
  });
};

/*
 * POST
 * Password recovery
 */
exports.passwordRecovery = function(req, res, next) {
  var email = req.body.email;
  db.users.findByEmail(email, function(err, user) {
    if (err) {
      return next(err);
    }
    if(!user) {
      req.flash('error', 'User with email ' + email +' is not registred');
      return res.redirect('forgotpassword');
    }
    return smtp.passwordSend(req, res, next, user);
  });
};

/*
 * GET
 * Check mail page
 */
exports.checkMail = function(req, res) {
  res.render('/users/check_mail', {
    message: req.flash('message')
  });
};
