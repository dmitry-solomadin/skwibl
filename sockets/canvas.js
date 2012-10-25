/******************************************
 *                CANVAS                  *
 ******************************************/


/**
 * Module dependencies.
 */

var db = require('../db')
  , tools = require('../tools');

exports.configure = function (sio) {

  sendInitData = function (project, socket) {
    var clients = sio.sockets.clients('canvas/' + project);

    // get canvas saved elements
  };

  var canvas = sio.of('/canvas');

  canvas.on('connection', function (socket) {

    var hs = socket.handshake
    id = hs.user.id;

    db.projects.current(id, function (err, project) {
      if (err || !project) {
        console.log(err, project);
        return socket.disconnect();
      }

      socket.join(project);
      socket.project = project;

      sendInitData(project, socket);

      socket.on('disconnect', function () {
        console.log('A socket with sessionId ' + hs.sessionId + ' disconnected.');
        socket.leave(socket.project);
      });

      socket.on('elementUpdate', function (msg, cb) {
        socket.broadcast.to(socket.project).emit("elementUpdate", {id:id, message:msg});
      });

      socket.on('elementRemove', function (msg, cb) {
        socket.broadcast.to(socket.project).emit("elementRemove", {id:id, message:msg});
      });

      socket.on('commentUpdate', function (msg, cb) {
        socket.broadcast.to(socket.project).emit("commentUpdate", {id:id, message:msg});
      });

      socket.on('commentRemove', function (msg, cb) {
        socket.broadcast.to(socket.project).emit("commentRemove", {id:id, message:msg});
      });

      socket.on('commentText', function (msg, cb) {
        socket.broadcast.to(socket.project).emit("commentText", {id:id, message:msg});
      });

      socket.on('eraseCanvas', function (msg, cb) {
        socket.broadcast.to(socket.project).emit("eraseCanvas");
      });

      socket.on('nextId', function (msg, cb) {
        socket.broadcast.to(socket.project).emit("nextId");
      });
    });

  });

};
