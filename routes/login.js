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
  app.get('/', ctrls.index);

 /*
  * logout
  */
  app.get('/logout', ctrls.isAuth, ctrls.logOut);

 /*
  * post local auth data
  */
  app.post('/login', ctrls.local(passport), ctrls.login);

 /*
  * post local registration info
  */
  app.post('/register', ctrls.register);

 /*
  * confirm local registration
  */
  app.get('/confirm/:hash', ctrls.hash(passport), ctrls.regConfirm, ctrls.dashboard);

 /*
  * auth or register with google
  */
  app.get('/auth/google', passport.authenticate('google'), ctrls.empty);

 /*
  * google callback
  */
  app.get('/auth/google/callback', ctrls.googleCb(passport), ctrls.dashboard);

 /*
  * auth or register with facebook
  */
  app.get('/auth/facebook', ctrls.facebook(passport), ctrls.empty);

 /*
  * facebook callback
  */
  app.get('/auth/facebook/callback', ctrls.facebookCb(passport), ctrls.dashboard);

 /*
  * auth or register with vkontakte
  */
  app.get('/auth/vkontakte', passport.authenticate('vkontakte'), ctrls.empty);

 /*
  * vkontakte callback
  */
  app.get('/auth/vkontakte/callback', ctrls.vkontakteCb(passport), ctrls.dashboard);

 /*
  * auth or register with twitter
  */
  app.get('/auth/twitter', passport.authenticate('twitter'));

 /*
  * twitter callback
  */
  app.get('/auth/twitter/callback', ctrls.twitterCb(passport), ctrls.dashboard);

}
