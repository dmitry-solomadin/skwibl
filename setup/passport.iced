passport = require 'passport'

db = require '../db'
tools = require '../tools'
cfg = require '../config'

LocalStrategy = require('passport-local').Strategy
HashStrategy = require('passport-hash').Strategy
GoogleStrategy = require('passport-google-oauth').OAuth2Strategy
FacebookStrategy = require('passport-facebook').Strategy
LinkedInStrategy = require('passport-linkedin').Strategy
cookie = require 'cookie'

exports.setUp = ->

  passport.serializeUser (user, done) ->
    done null, user

  passport.deserializeUser (user, done) ->
    done null, user
#     db.users.findById id, (err, user) ->
#       done err, user

  passport.use new LocalStrategy
    usernameField: 'email'
    passwordField: 'password'
  , (username, password, done) ->
    unless cfg.ENVIRONMENT is 'development' or tools.isEmail(username)
      return done null, no, message: "Incorrect email adress #{username}"
    db.users.findByEmail username, (err, user) ->
      return done err if err
      unless user
        return done null, no, message: "Unknown user #{username}"
      if user.password isnt password
        return done null, no, message: 'Invalid password'
      if user.status is 'unconfirmed' and cfg.ENVIRONMENT is 'development'
        return db.users.persist user, done
      if user.status is 'deleted'
        return db.users.restore user, done
      return done null, user

  passport.use new HashStrategy (hash, done) ->
    db.users.findByHash hash, (err, user) ->
      return done err if err
      unless user
        return done null, no, message: "Can not get user by hash #{hash}"
      if user.status isnt 'unconfirmed'
        return done null, no, message: 'This user is already registred'
      return done null, user

  passport.use new GoogleStrategy
    clientID: cfg.GOOGLE_CLIENT_ID
    clientSecret: cfg.GOOGLE_CLIENT_SECRET
    callbackURL: "#{cfg.DOMAIN}/auth/google/callback"
  , (accessToken, refreshToken, profile, done) ->
    db.auth.findOrCreate profile, accessToken, refreshToken, done

  passport.use new FacebookStrategy
    clientID: cfg.FACEBOOK_APP_ID
    clientSecret: cfg.FACEBOOK_APP_SECRET
    callbackURL: "#{cfg.DOMAIN}/auth/facebook/callback"
    profileFields: [
      'id'
      'photos'
      'name'
      'username'
      'first_name'
      'last_name'
      'middle_name'
      'displayName'
      'gender'
      'profileUrl'
      'emails'
    ]
  , (accessToken, refreshToken, profile, done) ->
    db.auth.findOrCreate profile, accessToken, refreshToken, done

  passport.use new LinkedInStrategy
    consumerKey: cfg.LINKEDIN_CONSUMER_KEY
    consumerSecret: cfg.LINKEDIN_CONSUMER_SECRET
    callbackURL: "#{cfg.DOMAIN}/auth/linkedin/callback"
    profileFields: [
      'id'
      'first-name'
      'last-name'
      'email-address'
      'picture-url'
      'headline'
    ]
  , (token, tokenSecret, profile, done) ->
    db.auth.findOrCreate profile, token, tokenSecret, done

  return passport
