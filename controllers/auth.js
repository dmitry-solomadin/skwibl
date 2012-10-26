/******************************************
 *            LOGIN & REGISTER            *
 ******************************************/


/**
 * Module dependencies.
 */

var db = require('../db')
  , smtp = require('../smtp')
  , tools = require('../tools');

/*
 * GET
 * main page
 */
exports.mainPage = function(req, res) {
  if (req.user) {
    return res.render('index', {
      template:'partials/user'
    , user:req.user
    , error:req.flash('error')});
  }

  return res.render('index', {
    template:'partials/mainpage'
  , error:req.flash('error')
  });
};

/*
 * GET
 * registration page
 */
exports.regPage = function(req, res) {
  return res.render('index', {
    template:'partials/registration'
    , error:req.flash('error')});
};

/*
 * POST
 * Local registration
 */
exports.register = function(req, res, next) {
  if(req.body != null) {
    var email = req.body.email;
    db.users.findByEmail(email, function(err, user) {
      if(err) {
        return next(err);
      }
      if (!user) {
        var hash = tools.hash(email);
        return db.users.add({
          hash: hash,
          displayName: req.body.name,
          password: req.body.password,
          status: 'unconfirmed',
          provider: 'local'
        }, null, [{
          value: email,
          type: 'main'
        }], function(err, user) {
          if(err) {
            return next(err);
          }
          if(!user) {
            req.flash('error', 'Registration failed. Can not create user for email: ' + email);
            return res.redirect('/');
          }
          return smtp.regNotify(req, res, next, user, hash);
        });
      }
      if(user.status === 'deleted') {
        return db.users.restore(user, function(err) {
          if(!err) {
            return smtp.passwordSend(req, res, next, user);
          }
          return next(err);
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
 * POST
 * Local authenticate
 */
exports.local = function (passport) {
  return function (req, res, next) {
    passport.authenticate('local', function (err, user, info) {
      if (!user) {
        return res.send(info)
      }

      req.logIn(user, function () {
        return res.send("OK");
      })
    })(req, res);
  }
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
exports.google = function(passport) {
  return passport.authenticate('google', {
    scope: [
      'https://www.googleapis.com/auth/userinfo.profile'
    , 'https://www.googleapis.com/auth/userinfo.email'
    ]
  });
};

/*
 * GET
 * Google authentication callback
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
  });
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
 * Twitter authenticate
 */
exports.twitter = function(passport) {
  return passport.authenticate('twitter');
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
 * GET
 * Registration confirm
 */
exports.confirm = function(req, res, next) {
  var id = req.user.id;
  return db.users.findById(id, function(err, user) {
    if(err) {
      req.flash('error', 'Problem while registring user');
      return res.redirect('/');
    }
    return db.users.persist(user, next);
  });
};

/*
 * GET
 * Redirect to main page
 */
exports.logIn = function(req, res) {
  res.redirect('/');
}

/*
 * GET
 * Logout
 */
exports.logOut = function(req, res) {
  req.logOut();
  res.redirect('/');
};
