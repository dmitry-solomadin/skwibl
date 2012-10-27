
var db = require('../db')
  , tools = require('../tools')
  , cfg = require('../config');

exports.player = function(req, res) {
  return res.render('dev/index', {
    template: 'player'
  , user: req.user
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
      , user: user
      , id: user.id
      , name: name
      , connections: conns
      });
    }
    return next(err);
  });
};
