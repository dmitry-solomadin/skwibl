exports.player = function(req, res) {
  res.render('dev/index', {template: 'player'});
};

exports.room = function(req, res) {
  res.render('dev/index', {template: 'room'});
};