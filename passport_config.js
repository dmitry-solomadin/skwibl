
/**
 * Module dependencies.
 */

var passport = require('passport');

var db = require('./db')
  , cfg = require('./config');

var LocalStrategy = require('passport-local').Strategy
  , HashStrategy = require('passport-hash').Strategy
  , GoogleStrategy = require('passport-google-oauth').OAuth2Strategy
  , FacebookStrategy = require('passport-facebook').Strategy
  , LinkedInStrategy = require('passport-linkedin').Strategy
  , cookie = require('cookie');

exports.setUp = function() {

  passport.serializeUser(function(user, done) {
    done(null, user);
  });

  passport.deserializeUser(function(user, done) {
    done(null, user);
//     db.users.findById(id, function (err, user) {
//       done(err, user);
//     });
  });

  passport.use(new LocalStrategy({
    usernameField: 'email',
    passwordField: 'password'
  },
  function(username, password, done) {
    db.users.findByEmail(username, function(err, user) {
      if(err) {
        return done(err);
      }
      if(!user) {
        return done(null, false, { message: 'Unknown user ' + username });
      }
      if(user.password != password) {
        return done(null, false, { message: 'Invalid password' });
      }
      if(user.status === 'unconfirmed') {
        return db.users.persist(user, done);
      }
      if(user.status === 'deleted') {
        return db.users.restore(user, done);
      }
      return done(null, user);
    })
  }));

  passport.use(new HashStrategy(function(hash, done) {
    db.users.findByHash(hash, function(err, user) {
      if (err) {
        return done(err);
      }
      if (!user) {
        return done(null, false, { message: 'Can not get user by hash ' + hash });
      }
      if (user.status != 'unconfirmed') {
        return done(null, false, { message: 'This user is already registred' });
      }
      return done(null, user);
    });
  }));

  passport.use(new GoogleStrategy({
    clientID: cfg.GOOGLE_CLIENT_ID,
    clientSecret: cfg.GOOGLE_CLIENT_SECRET,
    callbackURL: cfg.DOMAIN + '/auth/google/callback'
  }, function(accessToken, refreshToken, profile, done) {
    db.auth.findOrCreate(profile, accessToken, done);
  }));

  passport.use(new FacebookStrategy({
    clientID: cfg.FACEBOOK_APP_ID,
    clientSecret: cfg.FACEBOOK_APP_SECRET,
    callbackURL: cfg.DOMAIN + '/auth/facebook/callback'
  }, function(accessToken, refreshToken, profile, done) {
    db.auth.findOrCreate(profile, accessToken, done);
  }));

  passport.use(new LinkedInStrategy({
    consumerKey: cfg.LINKEDIN_CONSUMER_KEY,
    consumerSecret: cfg.LINKEDIN_CONSUMER_SECRET,
    callbackURL: cfg.DOMAIN + '/auth/linkedin/callback'
  },
  function(token, tokenSecret, profile, done) {
    db.auth.findOrCreate(profile, token, done);
  }));

  return passport;

};