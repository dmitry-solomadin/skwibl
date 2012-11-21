var db = require('../db')

exports.configure = function (sio) {

  var activities = sio.of('/activities');

  activities.on('connection', function (socket) {

    var hs = socket.handshake,
      id = hs.user.id;

    socket.join("activities" + id);

    db.activities.getAllNew(id, function (err, activities) {
      socket.emit("init", activities.length);
    });

    socket.on('disconnect', function () {

    });

  });

};
