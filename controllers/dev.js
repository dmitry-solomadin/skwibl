
var db = require('../db')
  , tools = require('../tools');

exports.player = function(req, res) {
  return res.render('dev/index', {
    template: 'player'
  });
};
