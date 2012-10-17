/******************************************
 *                CANVAS                  *
 ******************************************/


/**
 * Module dependencies.
 */

var db = require('../db')
  , tools = require('../tools');

exports.configure = function(sio) {

  sendInitData = function(project, socket) {
    var clients = sio.sockets.clients('canvas/' + project);

    // get canvas saved elements
  };

  var canvas = sio.of('/canvas');

  canvas.on('connection', function(socket) {

    var hs = socket.handshake
    id = hs.user.id;

    db.projects.current(id, function(err, project) {
      if(err || !project) {
        console.log(err, project);
        return socket.disconnect();
      }

      console.log("!!!" + socket);

      socket.join(project);
      socket.project = project;

      sendInitData(project, socket);

      socket.on('disconnect', function(){
        console.log('A socket with sessionId ' + hs.sessionId + ' disconnected.');
        socket.leave(socket.project);
      });

      socket.on('message', function(msg, cb) {
        socket.broadcast.to(socket.project).json.send({
          id: id
          , message: msg
        });
      });
    });

  });

};
