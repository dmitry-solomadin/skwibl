
var db = require('../db')
  , tools = require('../tools');

exports.player = function(req, res) {
  return res.render('dev/index', {
    template: 'player'
  });
};

exports.room = function(req, res) {
  return res.render('dev/index', {
    template: 'room'
  });
};

exports.chat = function(req, res) {
  var user = req.user
    , name = tools.getName(user);
  return res.render('dev/index', {
    template: 'chat'
  , id: user.id
  , name: name
  });
};

exports.switchProject = function(req, res) {
  console.log('switch to project' + req.body.id);
  res.send(true);
};

exports.projects = function(req, res, next) {
  db.projects.get(req.user.id, function(err, projects) {
    var user = req.user
      , name = tools.getName(user);
    if(!err) {
      return db.activities.get(req.user.id, function(err, activities) {
        if(!err) {
          return res.render('dev/index', {
            template: 'projects'
          , projects: projects
          , activities: activities
          , id: user.id
          , name: name
          });
        }
        return next(err);
      });
    }
    return next(err);
  });
};

exports.getProject = function(req, res) {
  db.projects.getData(req.body.pid, req.user.id, function(err, project) {
    if(!err) {
      return res.send(project);
    }
    return res.send(false);
  });
};
