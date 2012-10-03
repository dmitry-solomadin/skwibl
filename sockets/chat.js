/******************************************
 *                  CHAT                  *
 ******************************************/


/**
 * Module dependencies.
 */

var db = require('../db')
  , tools = require('../tools');

exports.configure = function(sio) {

  var chat = sio.of('/chat');

  chat.on('connection', function(socket) {

    var hs = socket.handshake;
    console.log('A socket with sessionId '+hs.sessionId+' connected.' + socket.id);

    //TODO Get current user project
    var project = 1;
    socket.join(project);
    socket.project = project;

//     console.log('room list');
//     console.log(sio.sockets.manager.rooms);
//     console.log('clients in room 1');
//     console.log(sio.sockets.clients('chat/1'));
//     console.log('rooms a client join');
//     console.log(sio.sockets.manager.roomClients[socket.id]);

    var clients = sio.sockets.clients('chat/' + project);

    //TODO change to return all project users with status in/out of project
    socket.json.emit('users', tools.getUsers(clients, project));
    db.actions.get(project, 'chat', function(err, actions) {
      if(actions.length !== 0) {
        socket.json.emit('messages', actions);
      }
    });

    socket.on('disconnect', function(){
      console.log('A socket with sessionId ' + hs.sessionId + ' disconnected.');
      socket.leave(socket.project);
      socket.broadcast.to(socket.project).emit('exit', hs.user.id);
    });

    socket.on('message', function(msg, cb) {
      socket.broadcast.to(socket.project).json.send({
        id: hs.user.id
      , message: msg
      });
      db.actions.add(socket.project, hs.user.id, 'chat', msg);
    });

    socket.on('enter', function(project) {
      //assume that project is valid user project
      socket.project = project;
      socket.join(project);
      socket.broadcast.to(project).emit('enter', hs.user.id);
    });

    socket.on('exit', function() {
      socket.leave(socket.project);
      socket.broadcast.to(socket.project).emit('exit', hs.user.id);
      socket.project = null;
    });

    //TODO Change to pub/sub
    socket.on('switch', function(project) {
      socket.leave(socket.project);
      socket.broadcast.to(socket.project).emit('exit', hs.user.id);
      socket.project = project;
      socket.join(project);
      socket.broadcast.to(project).emit('enter', hs.user.id);
    });

//     socket.json.emit('list', users);
//     socket.broadcast.json.emit('enter', hs.session.name);
//
//     socket.on('message', function(message) {
//       socket.broadcast.json.emit({
//         id: hs.session.uid,
//         message: message,
//         time: new Date
//       });
//     });

  });

}
