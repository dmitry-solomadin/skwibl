exports.player = function(req, res) {
  return res.render('dev/index', {template: 'player'});
};

exports.room = function(req, res) {
  return res.render('dev/index', {template: 'room'});
};