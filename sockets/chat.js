/******************************************
 *                  CHAT                  *
 ******************************************/


/**
 * Module dependencies.
 */

var db = require('../db')
  , tools = require('../tools');

exports.configure = function(sio) {

  sendInitData = function(project, socket) {
    var clients = sio.sockets.clients('chat/' + project);

    db.projects.getUsers(project, function(err, users) {
      if(!err && users) {
        var loggedIn = tools.getUsers(clients, project);
        users.forEach(function(user) {
          if(loggedIn.indexOf(user.id) !== -1) {
            user.status = 'online';
          }
        });
        socket.json.emit('users', users);
      }
    });

    db.actions.get(project, 'chat', function(err, actions) {
      if(actions.length !== 0) {
        socket.json.emit('messages', actions);
      }
    });
  };

  var chat = sio.of('/chat');

  chat.on('connection', function(socket) {

    var hs = socket.handshake
        id = hs.user.id;

    db.projects.current(id, function(err, project) {
      if(err || !project) {
        console.log(err, project);
        return socket.disconnect();
      }

      socket.join(project);
      socket.project = project;

      sendInitData(project, socket);

      socket.broadcast.to(project).emit('enter', id);

      socket.on('disconnect', function(){
        console.log('A socket with sessionId ' + hs.sessionId + ' disconnected.');
        socket.leave(socket.project);
        socket.broadcast.to(socket.project).emit('exit', id);
      });

      socket.on('message', function(msg, cb) {
        socket.broadcast.to(socket.project).json.send({
          id: id
        , message: msg
        });
        db.actions.add(socket.project, id, 'chat', msg);
      });

      //TODO temporary function for testing
      socket.on('switch', function(project) {
        //assume that project is valid user project
        socket.leave(socket.project);
        socket.broadcast.to(socket.project).emit('exit', id);
        socket.project = project;
        socket.join(project);
        db.projects.set(id, project);
        console.log('switch ',project);
        socket.broadcast.to(project).emit('enter', id);
        sendInitData(project, socket);
      });
    });

  });

}
