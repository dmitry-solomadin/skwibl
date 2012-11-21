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
    // get canvas saved elements
  };

  var canvas = sio.of('/canvas');

  canvas.on('connection', function(socket) {

    var hs = socket.handshake
      , id = hs.user.id;

    db.projects.current(id, function(err, project) {
      if (err || !project) {
        console.log(err, project);
        return socket.disconnect();
      }

      socket.join(project);
      socket.project = project;

      sendInitData(project, socket);

      socket.on('disconnect', function() {
        console.log('A socket with sessionId ' + hs.sessionId + ' disconnected.');
        socket.leave(socket.project);
      });

      socket.on('elementUpdate', function(data, cb) {
        console.log('elupdate');
        console.log(data);
        socket.broadcast.to(socket.project).emit("elementUpdate", {
          id: id
        , canvasId: data.canvasId
        , element: data.element
        });
        db.actions.update(socket.project, id, 'element', data);
      });

      socket.on('elementRemove', function(data, cb) {
        console.log('elremove');
        console.log(data);
        socket.broadcast.to(socket.project).emit("elementRemove", {
          id: id
        , canvasId: data.canvasId
        , elementId: data.elementId
        });
        db.actions.remove(data.elementId);
      });

      socket.on('commentUpdate', function(data, cb) {
        console.log('coupdate');
        console.log(data);
        data.comment = true;
        socket.broadcast.to(socket.project).emit("commentUpdate", {
          id: id
        , canvasId: data.canvasId
        , element: data.element
        });
        db.actions.update(socket.project, id, 'element', data);
      });

      socket.on('commentRemove', function(data, cb) {
        console.log('cormove');
        console.log(data);
        socket.broadcast.to(socket.project).emit("commentRemove", {
          id: id
        , cancasId: data.cancasId
        , elementId: data.elementId
        });
        db.actions.remove(data.elementId);
      });

      socket.on('commentText', function(data, cb) {
        console.log('cotext');
        console.log(data);
        socket.broadcast.to(socket.project).emit("commentText", {
          id: id
        , canvasId: data.canvasId
        , element: data.element
        });
        db.actions.updateComment(data);
      });

      socket.on('eraseCanvas', function(data, cb) {
        console.log('erasecanv');
        console.log(data);
        socket.broadcast.to(socket.project).emit("eraseCanvas", {
          id: id
        , canvasId: data.cancasId
        });
      });

      socket.on('canvasAdded', function(data, cb) {
        console.log('canvasadd');
        console.log(data);
        //TODO move to socket anounce
        socket.broadcast.to(socket.project).emit("fileAdded", {
          id: id
        , canvasId: data.canvasId
        , element: data.element
        });
      });

      socket.on('switchCanvas', function (msg, cb) {
        socket.broadcast.to(socket.project).emit("switchCanvas", {id:id, canvasIndex:msg});
      });

    });

  });

};
