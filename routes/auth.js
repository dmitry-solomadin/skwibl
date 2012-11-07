/******************************************
 *            LOGIN & REGISTER            *
 ******************************************/


/**
 * Module dependencies.
 */

var ctrls = require('../controllers');

exports.configure = function(app, passport) {

  /*
   * get login page
   */
  app.get('/', ctrls.auth.mainPage);

  /*
   * get registration page
   */
  app.get('/registration', ctrls.auth.regPage);

  /*
   * post local registration info
   */
  app.post('/register', ctrls.auth.register);

  /*
   * post local auth data
   */
  app.post('/login', ctrls.auth.local(passport));

  /*
   * confirm local registration
   */
  app.get('/confirm/:hash', ctrls.auth.hash(passport), ctrls.auth.confirm, ctrls.auth.logIn);

  /*
   * auth or register with google
   */
  app.get('/auth/google', ctrls.auth.google(passport), ctrls.aux.empty);

  /*
   * google callback
   */
  app.get('/auth/google/callback', ctrls.auth.googleCb(passport), ctrls.auth.logIn);

  /*
   * connect google
   */
  app.get('/connect/google', ctrls.auth.connectGoogle);

  /*
   * connect google callback
   */
  app.get('/connect/google/callback', ctrls.auth.connectGoogleCb);

  /*
   * auth or register with facebook
   */
  app.get('/auth/facebook', ctrls.auth.facebook(passport), ctrls.aux.empty);

  /*
   * facebook auth callback
   */
  app.get('/auth/facebook/callback', ctrls.auth.facebookCb(passport), ctrls.auth.logIn);

  /*
   * connect facebook
   */
  app.get('/connect/facebook', ctrls.auth.connectFacebook);

  /*
   * connect facebook callback
   */
  app.get('/connect/facebook/callback', ctrls.auth.connectFacebookCb);

  /*
   * auth or register with linkedin
   */
  app.get('/auth/linkedin', ctrls.auth.linkedin(passport));

  /*
   * linkedin callback
   */
  app.get('/auth/linkedin/callback', ctrls.auth.linkedinCb(passport), ctrls.auth.logIn);

  /*
   * connect linkedin
   */
  app.get('/connect/linkedin', ctrls.auth.connectLinkedin);

  /*
   * connect linkedin callback
   */
  app.get('/connect/linkedin/callback', ctrls.auth.connectLinkedinCb);

  /*
   * connect dropbox
   */
  app.get('/connect/dropbox', ctrls.auth.connectDropbox);

  /*
   * connect dropbox callback
   */
  app.get('/connect/dropbox/callback', ctrls.auth.connectDropboxCb);

  /*
   * connect yahoo
   */
  app.get('/connect/yahoo', ctrls.auth.connectYahoo);

  /*
   * connect yahoo callback
   */
  app.get('/connect/yahoo/callback', ctrls.auth.connectYahooCb);

  /*
   * disconnect from side service
   */
  app.post('/auth/disconnect', ctrls.mid.isAuth, ctrls.auth.disconnect);

  /*
   * logout
   */
  app.get('/logout', ctrls.mid.isAuth, ctrls.auth.logOut);

}
