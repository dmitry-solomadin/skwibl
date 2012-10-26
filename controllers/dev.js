
var db = require('../db')
  , tools = require('../tools')
  , cfg = require('../config');

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

exports.projects = function(req, res, next) {
  var user = req.user
    , name = tools.getName(user);
  db.projects.get(user.id, function(err, projects) {
    if(!err) {
      return db.activities.get(user.id, function(err, activities) {
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

exports.showProject = function(req, res, next) {
  var pid = req.params.pid
    , user = req.user
    , name = tools.getName(user);
  db.projects.set(user.id, pid, function(err, val) {
    if(!err) {
      return db.projects.get(user.id, function(err, projects) {
        if(!err) {
          return res.render('dev/index', {
            template: 'chat'
          , projects: projects
          , id: user.id
          , pid: pid
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

exports.connections = function(req, res, next) {
  var user = req.user
    , name = tools.getName(user);
  db.auth.connections(user.id, function(err, obj) {
    if(!err) {
      var conns = {
        facebook: 'disconnected'
      , google: 'disconnected'
      , linkedin: 'disconnected'
      , dropbox: 'disconnected'
      , yahoo: 'disconnected'
      };
      if(obj) {
        for(el in conns) {
          if(obj[el]) {
            conns[el] = 'connected';
          }
        }
      }
      return res.render('dev/index', {
        template: 'profile'
      , id: user.id
      , name: name
      , connections: conns
      });
    }
    return next(err);
  });
};
