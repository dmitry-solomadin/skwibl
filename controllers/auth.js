/******************************************
 *            LOGIN & REGISTER            *
 ******************************************/


/**
 * Module dependencies.
 */

var request = require('request')
  , qs = require('querystring');

var db = require('../db')
  , smtp = require('../smtp')
  , tools = require('../tools')
  , cfg = require('../config');

/*
 * GET
 * main page
 */
exports.mainPage = function(req, res) {
  if (req.user) {
    return res.redirect("/projects")
  }

  return res.render('index', {
    template:'./mainpage'
  });
};

/*
 * GET
 * registration page
 */
exports.regPage = function(req, res) {
  return res.render('index', {
    template:'users/new'
  });
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
            tools.addError(req, 'Enter valid email.');
            return res.redirect('/registration');
          }
          return smtp.regNotify(req, res, next, user, hash);
        });
      }
      if(user.status === 'deleted') {
        return db.users.restore(user, function(err) {
          if(!err) {
            return smtp.passwordSend(req, res, user, function (err, message){
              if (err) {
                req.flash('error', 'Unable send confirmation to ' + email);
                return res.redirect('/');
              } else {
                req.flash('message', 'Password successfuly sent to email: ' + email);
                return res.redirect('/checkmail');
              }
            });
          }
          return next(err);
        });
      }
      tools.addError(req, 'This mail is already in use: ' + email);
      return res.redirect('/registration');
    });
  } else {
    tools.addError(req, 'Invalid user mail or password: ' + email);
    return res.redirect('/registration');
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
  //patch to access_type=offline or save token into session
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
 * POST
 * Google connect
 */
exports.connectGoogle = function(req, res, next) {
  return res.redirect('https://accounts.google.com/o/oauth2/auth?'
  + 'client_id=' + cfg.GOOGLE_CLIENT_ID + '&'
  + 'redirect_uri=http%3A%2F%2Flocalhost/connect/google/callback&'
  + 'response_type=code&' + 'scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.email+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.profile');//&access_type=offline');
};

/*
 * GET
 * Google connect callback
 */
exports.connectGoogleCb = function(req, res) {
  var code = req.query['code']
    , tokenURL = 'https://accounts.google.com/o/oauth2/token'
    , oauth = {
      code: code
    , client_id: cfg.GOOGLE_CLIENT_ID
    , client_secret: cfg.GOOGLE_CLIENT_SECRET
    , redirect_uri: 'http://localhost/connect/google/callback'
    , grant_type: 'authorization_code'
    };
    return request.post(tokenURL, function(error, response, body) {
    if (!error && response.statusCode == 200) {
      var ans = JSON.parse(body);
      console.log(body);
      return db.auth.connect(req.user.id, 'google', ans.access_token, function(err, val) {
        return res.redirect('/dev/conns');
      });
    }
    return res.redirect('/dev/conns');
  }).form(oauth);
};

/*
 * GET
 * Facebook authenticate
 */
exports.facebook = function(passport) {
  return passport.authenticate('facebook', {
    scope: [
      'email'
    , 'offline_access'
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
 * POST
 * Facebook connect
 */
exports.connectFacebook = function(req, res, next) {
  return res.redirect('https://graph.facebook.com/oauth/authorize?'
  + 'client_id=' + cfg.FACEBOOK_APP_ID + '&'
  + 'redirect_uri=http%3A%2F%2Flocalhost/connect/facebook/callback&'
  + 'scope=email,user_online_presence');
};

/*
 * GET
 * Facebook connect callback
 */
exports.connectFacebookCb = function(req, res) {
  var code = req.query['code']
    , tokenURL = 'https://graph.facebook.com/oauth/access_token?'
    + 'client_id=' + cfg.FACEBOOK_APP_ID
    + '&redirect_uri=http%3A%2F%2Flocalhost/connect/facebook/callback'
    + '&client_secret=' + cfg.FACEBOOK_APP_SECRET
    + '&code=' + code;
  return request(tokenURL, function(error, response, body) {
    if (!error && response.statusCode == 200) {
      var ans = qs.parse(body);
      console.log(body);
      return db.auth.connect(req.user.id, 'facebook', ans.access_token, function(err, val) {
        return res.redirect('/dev/conns');
      });
    }
    return res.redirect('/dev/conns');
  });
};

/*
 * GET
 * LinkedIn authenticate
 */
exports.linkedin = function(passport) {
  return passport.authenticate('linkedin');
};

/*
 * GET
 * LinkedIn authentication callback
 */
exports.linkedinCb = function(passport) {
  return passport.authenticate('linkedin', {
    failureRedirect: '/'
  });
};

exports.connectLinkedin = function(req, res) {
  var oauth = {
      callback: 'http://localhost/connect/linkedin/callback/'
    , consumer_key: cfg.LINKEDIN_CONSUMER_KEY
    , consumer_secret: cfg.LINKEDIN_CONSUMER_SECRET
    }
    , url = '   https://api.linkedin.com/uas/oauth/requestToken?scope=r_basicprofile+r_emailaddress';
  return request.post({url: url, oauth: oauth}, function(error, responce, body) {
    console.log(error, responce.statusCode);
    console.log(body);
    if(!error && responce.statusCode == 200) {
      var ans = qs.parse(body);
      console.log(ans);
      res.redirect(ans.xoauth_request_auth_url + '?oauth_token=' + ans.oauth_token);
    }
  });
};

exports.connectLinkedinCb = function(req, res) {
  var token = req.query['oauth_token']
    , verifier = req.query['oauth_verifier'];
  return db.auth.connect(req.user.id, 'linkedin', token, function(err, val) {
    return res.redirect('/dev/conns');
  });
};

exports.connectDropbox = function(req, res) {
  var oauth = {
    callback: 'http://localhost/connect/dropbox/callback/'
  , consumer_key: cfg.DROPBOX_APP_KEY
  , consumer_secret: cfg.DROPBOX_APP_SECRET
  }
  , url = 'https://api.dropbox.com/1/oauth/request_token';
  return request.post({url: url, oauth: oauth}, function(error, responce, body) {
    console.log(error, responce.statusCode);
    console.log(body);
    if(!error && responce.statusCode == 200) {
      var ans = qs.parse(body);
      console.log(ans);
      res.redirect('https://www.dropbox.com/1/oauth/authorize?oauth_token='
      + ans.oauth_token +
      '&oauth_callback=http://localhost/connect/dropbox/callback'
      );
    }
  });
};

exports.connectDropboxCb = function(req, res) {
  var token = req.query['oauth_token']
    , uid = req.query['uid'];
  return db.auth.connect(req.user.id, 'dropbox', token, function(err, val) {
    return res.redirect('/dev/conns');
  });
};

//Yahoo does not support localhost
exports.connectYahoo = function(req, res) {
  var oauth = {
    callback: 'http://localhost/connect/linkedin/callback/'
  , consumer_key: cfg.YAHOO_CONSUMER_KEY
  , consumer_secret: cfg.YAHOO_CONSUMER_SECRET
  }
  , url = 'https://api.login.yahoo.com/oauth/v2/get_request_token';
  return request.post({url: url, oauth: oauth}, function(error, responce, body) {
    console.log(error, responce.statusCode);
    console.log(body);
    if(!error && responce.statusCode == 200) {
      var ans = qs.parse(body);
      console.log(ans);
      res.redirect(ans.xoauth_request_auth_url + '?oauth_token=' + ans.oauth_token);
    }
  });
};

exports.connectYahooCb = function(req, res) {
  var token = req.query['oauth_token']
    , verifier = req.query['oauth_verifier'];
  return db.auth.connect(req.user.id, 'dropbox', token, function(err, val) {
    return res.redirect('/dev/conns');
  });
};

/*
 * POST
 * Disconnect side service
 */
exports.disconnect = function(req, res) {
  db.auth.disconnect(req.user.id, req.body.provider, function(err) {
    tools.returnStatus(err, res);
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
