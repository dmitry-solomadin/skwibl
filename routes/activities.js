var ctrls = require('../controllers');

exports.configure = function(app, passport) {

  app.get('/activities', ctrls.mid.isAuth, ctrls.activities.index);

};