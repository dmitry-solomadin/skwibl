request = require 'request'
qs = require 'querystring'

smtp = require '../smtp'

#
# GET
# main page
#
exports.mainPage = (req, res) =>
  return res.redirect '/projects' if req.user
  res.render 'mainpage'

#
# GET
# registration page
#
exports.regPage = (req, res) =>
  return res.render 'index', template:'users/new'

#
# POST
# Local registration
#
exports.register = (req, res, next) =>
  error = false
  unless req.body.email.length
    @tools.addError req, "Please enter email"
    error = true

  unless req.body.givenName.length
    @tools.addError req, "Please enter first name"
    error = true

  unless req.body.familyName.length
    @tools.addError req, "Please enter last name"
    error = true

  unless req.body.password.length
    @tools.addError req, "Please enter password"
    error = true

  return res.redirect '/registration' if error

  email = req.body.email
  unless @cfg.ENVIRONMENT is 'development' or @tools.isEmail email
    @tools.addError req, "Incorrect email address: #{email}"
    return res.redirect '/registration'
  @db.users.findByEmail email, (err, user) =>
    return next err if err
    unless user
      hash = @tools.hash email
      givenName = req.body.givenName
      familyName = req.body.familyName
      return @db.users.add
        hash: hash
        displayName: "#{givenName} #{familyName}"
        password: req.body.password
        status: 'unconfirmed'
        provider: 'local'
      ,
        givenName: givenName
        familyName: familyName
      , [value: email], (err, user) =>
        return next err if err
        unless user
          @tools.addError req, 'Enter valid email.'
          return res.redirect '/registration'
        return smtp.regConfirm user, hash, (err, msg) =>
          if err
            req.flash 'error', "Can not send confirmation to  #{user.email}"
            return res.redirect '/registration'
          else
            req.flash 'message', "User with email: #{user.email} successfuly registred."
            return res.redirect '/checkmail'
    if user.status is 'deleted'
      return @db.users.restore user, (err) =>
        unless err
          return smtp.passwordSend user, (err, message) =>
            if err
              req.flash 'error', "Unable send confirmation to #{email}"
              return res.redirect '/registration'
            else
              req.flash 'message', "Password successfuly sent to email: #{email}"
              return res.redirect '/checkmail'
        return next err
    @tools.addError req, "This mail is already in use: #{email}"
    return res.redirect '/registration'

#
# POST
# Local authenticate
#
exports.local = (passport) =>
  return (req, res, next) =>
    passport.authenticate('local', (err, user, info) =>
      return res.send info unless user
      req.logIn user, =>
        return res.send 'OK'
    )(req, res)

#
# GET
# Link authenticate
#
exports.hash = (passport) =>
  return passport.authenticate 'hash',
    failureRedirect: '/'
    failureFlash: true

#
# GET
# Google authenticate
#
exports.google = (passport) =>
  return passport.authenticate 'google',
    scope: [
      'https://www.googleapis.com/auth/userinfo.profile'
      'https://www.googleapis.com/auth/userinfo.email'
    ]

#
# GET
#Google authentication callback
#
exports.googleCb = (passport) =>
  return passport.authenticate 'google', failureRedirect: '/'

#
# POST
# Google connect
#
exports.connectGoogle = (req, res, next) =>
  url = 'https://accounts.google.com/o/oauth2/auth?'
  params =
    client_id: @cfg.GOOGLE_CLIENT_ID
    response_type: code
    redirect_uri: "#{@cfg.DOMAIN}/connect/google/callback"
    scope: 'https://www.googleapis.com/auth/userinfo.email+https://www.googleapis.com/auth/userinfo.profile'
#     access_type: 'offline'
  return res.redirect url + qs.stringify params

#
# GET
# Google connect callback
#
exports.connectGoogleCb = (req, res) =>
  code = req.query['code']
  tokenURL = 'https://accounts.google.com/o/oauth2/token'
  oauth =
    code: code
    client_id: @cfg.GOOGLE_CLIENT_ID
    client_secret: @cfg.GOOGLE_CLIENT_SECRET
    redirect_uri: "#{@cfg.DOMAIN}/connect/google/callback"
    grant_type: 'authorization_code'
  return request.post(tokenURL, (error, response, body) =>
    if not error and (response.statusCode is 200 or response.statusCode is 302)
      ans = JSON.parse body
      console.log ans
      return @db.auth.connect req.user.id, 'google',
        access_token: ans.access_token
        oauth_token_secret: ans.oauth_token_secret
      , (err, val) =>
        return res.redirect '/dev/conns'
    return res.redirect '/dev/conns'
  ).form(oauth)

#
# GET
# Facebook authenticate
#
exports.facebook = (passport) =>
  return passport.authenticate 'facebook',
    scope: [
      'email'
      'offline_access'
      'user_status'
      'user_photos'
      'user_videos'
    ]

#
# GET
# Facebook authentication callback
#
exports.facebookCb = (passport) =>
  return passport.authenticate 'facebook', failureRedirect: "/"

#
# POST
# Facebook connect
#
exports.connectFacebook = (req, res, next) =>
  url = 'https://graph.facebook.com/oauth/authorize?'
  params =
    client_id: @cfg.FACEBOOK_APP_ID
    redirect_uri: "#{@cfg.DOMAIN}/connect/facebook/callback"
    scope: 'email,user_online_presence'
  return res.redirect url + qs.stringify params

#
# GET
# Facebook connect callback
#
exports.connectFacebookCb = (req, res) =>
  url = 'https://graph.facebook.com/oauth/access_token?'
  params =
    client_id: @cfg.FACEBOOK_APP_ID
    redirect_uri: "#{@cfg.DOMAIN}/connect/facebook/callback"
    client_secret: @cfg.FACEBOOK_APP_SECRET
    code: req.query['code']
  return request url + qs.stringify(params), (error, response, body) =>
    if not error and response.statusCode is 200
      ans = qs.parse body
      console.log ans
      return @db.auth.connect req.user.id, 'facebook',
        access_token: ans.access_token
      , (err, val) =>
        return res.redirect '/dev/conns'
    return res.redirect '/dev/conns'

#
# GET
# LinkedIn authenticate
#
exports.linkedin = (passport) =>
  return passport.authenticate 'linkedin',
    scope: [
      'r_basicprofile'
      'r_emailaddress'
    ]

#
# GET
# LinkedIn authentication callback
#
exports.linkedinCb = (passport) =>
  return passport.authenticate 'linkedin', failureRedirect: '/'

exports.connectLinkedin = (req, res) =>
  oauth =
    callback: "#{@cfg.DOMAIN}/connect/linkedin/callback/"
    consumer_key: @cfg.LINKEDIN_CONSUMER_KEY
    consumer_secret: @cfg.LINKEDIN_CONSUMER_SECRET
  url = '   https://api.linkedin.com/uas/oauth/requestToken?'
  params =
    scope: 'r_basicprofile+r_emailaddress'
  return request.post url: url + qs.stringify(params), oauth: oauth, (error, response, body) =>
    if not error and response.statusCode is 200
      ans = qs.parse body
      res.redirect ans.xoauth_request_auth_url + '?oauth_token=' + ans.oauth_token

exports.connectLinkedinCb = (req, res) =>
  token = req.query['oauth_token']
  verifier = req.query['oauth_verifier']
  console.log req.query
  return @db.auth.connect req.user.id, 'linkedin', token, (err, val) =>
    return res.redirect('/dev/conns')

exports.connectDropbox = (req, res) =>
  oauth =
    callback: "#{@cfg.DOMAIN}/connect/dropbox/callback/"
    consumer_key: @cfg.DROPBOX_APP_KEY
    consumer_secret: @cfg.DROPBOX_APP_SECRET
  url = 'https://api.dropbox.com/1/oauth/request_token'
  return request.post url: url, oauth: oauth, (error, response, body) =>
    if not error and response.statusCode is 200
      ans = qs.parse body
      console.log 'dropbox connect', ans
      return @db.auth.setConnection req.user.id, 'dropbox',
        oauth_token_secret: ans.oauth_token_secret
      , (err, val) =>
        url = 'https://www.dropbox.com/1/oauth/authorize?'
        params =
          oauth_token: ans.oauth_token
          oauth_callback: "#{@cfg.DOMAIN}/connect/dropbox/callback"
        return res.redirect url + qs.stringify params

exports.connectDropboxCb = (req, res) =>
  token = req.query['oauth_token']
  @db.auth.getConnection req.user.id, 'dropbox', (err, connection) =>
    url = 'https://api.dropbox.com/1/oauth/access_token'
    oauth =
      consumer_key: @cfg.DROPBOX_APP_KEY
      consumer_secret: @cfg.DROPBOX_APP_SECRET
      token: token
      token_secret: connection.oauth_token_secret
    console.log 'dropbox callback', req.query
    return request url: url, oauth: oauth, (err, response, body) =>
      console.log response.statusCode, body
      if not err and response.statusCode is 200
        ans = qs.parse body
        @db.auth.connect req.user.id, 'dropbox',
          oauth_token_secret: ans.oauth_token_secret
          oauth_token: ans.oauth_token
          uid: ans.uid
        , (err, val) =>
          return res.redirect '/dev/conns'

# Yahoo does not support localhost
exports.connectYahoo = (req, res) =>
  oauth =
    callback: "#{@cfg.DOMAIN}/connect/linkedin/callback/"
    consumer_key: @cfg.YAHOO_CONSUMER_KEY
    consumer_secret: @cfg.YAHOO_CONSUMER_SECRET
  url = 'https://api.login.yahoo.com/oauth/v2/get_request_token'
  return request.post url: url, oauth: oauth, (error, response, body) =>
    if not error and response.statusCode is 200
      ans = qs.parse body
      res.redirect ans.xoauth_request_auth_url + '?oauth_token=' + ans.oauth_token

exports.connectYahooCb = (req, res) =>
  token = req.query['oauth_token']
  verifier = req.query['oauth_verifier']
  console.log req.query
  return @db.auth.connect req.user.id, 'dropbox', token, (err, val) =>
    return res.redirect '/dev/conns'

#
# POST
# Disconnect side service
#
exports.disconnect = (req, res) =>
  @db.auth.disconnect req.user.id, req.body.provider, (err) =>
    @tools.returnStatus err, res

#
# GET
# Registration confirm
#
exports.confirm = (req, res, next) =>
  id = req.user.id
  return @db.users.findById id, (err, user) =>
    if err
      req.flash 'error', 'Problem while registring user'
      return res.redirect '/'
    return @db.users.persist user, next

#
# GET
# Redirect to main page
#
exports.logIn = (req, res) =>
  res.redirect '/'

#
# GET
# Logout
#
exports.logOut = (req, res) =>
  req.logOut()
  res.redirect '/'
