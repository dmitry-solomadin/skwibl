/******************************************
 *            LOGIN & REGISTER            *
 ******************************************/


/**
 * Module dependencies.
 */

var db = require('../db')
  , smtp = require('../smtp/smtp')
  , tools = require('../tools/tools');

/*
 * GET
 * Logout
 */
exports.logOut = function(req, res) {
  req.logOut();
  res.redirect('/');
};

/*
 * GET
 * Registration confirm
 */
exports.regConfirm = function(req, res, next) {
  var id = req.user.id;
  return db.findUserById(id, function(err, user) {
    if(err) {
      req.flash('error', 'Problem while registring user');
      return res.redirect('/');
    }
    return db.persistUser(user, next);
  });
};

/*
 * POST
 * Local authenticate
 */
exports.local = function(passport) {
  return passport.authenticate('local', {
    failureRedirect: '/'
    , failureFlash: true
  });
};

/*
 * GET
 * Link authenticate
 */
exports.hash = function(passport) {
  return passport.authenticate('hash', {
    failureRedirect: '/'
    , failureFlash: true
  });
};

/*
 * GET
 * Google authenticate
 */
exports.googleCb = function(passport) {
  return passport.authenticate('google', {
    failureRedirect: '/'
  });
};

/*
 * GET
 * Facebook authenticate
 */
exports.facebook = function(passport) {
  return passport.authenticate('facebook', {
    scope: [
    'email'
  , 'user_status'
  , 'user_checkins'
  , 'user_photos'
  , 'user_videos'
    ]
  })
};

/*
 * GET
 * Facebook authentication callback
 */
exports.facebookCb = function(passport) {
  return passport.authenticate('facebook', {
    failureRedirect: '/'
  });
};

/*
 * GET
 * Vkontakte authentication callback
 */
exports.vkontakteCb = function(passport) {
  return passport.authenticate('vkontakte', {
    failureRedirect: '/'
  });
};

/*
 * GET
 * Twitter authentication callback
 */
exports.twitterCb = function(passport) {
  return passport.authenticate('twitter', {
    failureRedirect: '/'
  });
};

/*
 * POST
 * Local registration
 */
exports.register = function(req, res, next) {
  if(req.body != null) {
    var email = req.body.email;
    db.findUserByMail(email, function(err, user) {
      if (err) {
        return next(err);
      }
      if (!user) {
        var hash = tools.hash(email);
        return db.addUser({
          hash: hash,
          displayName: req.body.name,
          password: req.body.password,
          status: 'unconfirmed',
          provider: 'local'
        }, null, [{
          value: email,
          type: 'main'
        }], function(err, user) {
          if (err) {
            return next(err);
          }
          if (!user) {
            req.flash('error', 'Registration failed. Can not create user for email: ' + email);
            return res.redirect('/');
          }
          return smtp.regNotify(req, res, next, user, hash)
          //           return db.expireUser(user, smtp.regNotify(req, res, next, user, hash));
        });
      }
      req.flash('error', 'This mail is already in use: ' + email);
      return res.redirect('/');
    });
  } else {
    req.flash('error', 'Invalid user mail or password: ' + email);
    return res.redirect('/');
  }
};

/*
 * GET
 * login page
 */
exports.index = function(req, res) {
  res.render('main', {
    template: 'mainpage'
  , user: req.user
  , message: req.flash('error')
  });
};
