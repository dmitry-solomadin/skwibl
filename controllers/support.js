/******************************************
 *             SUPPORT PAGES              *
 ******************************************/

/**
 * Module dependencies.
 */

var db = require('../db')
  , smtp = require('../smtp');

/*
 * POST
 * Password recovery
 */
exports.passwordRecovery = function(req, res) {
  var email = req.body.email;
  db.users.findByEmail(email, function(err, user) {
    if (err) {
      return res.send(false);
    }

    if(!user) {
      return res.send(false);
    }
    return smtp.passwordSend(req, res, user, function () {
      if (err) {
        return res.send(false);
      } else {
        return res.send(true);
      }
    });
  });
};

/*
 * GET
 * Check mail page
 */
exports.checkMail = function(req, res) {
  res.render('./users/check_mail', {
    message: req.flash('message')
  });
};
