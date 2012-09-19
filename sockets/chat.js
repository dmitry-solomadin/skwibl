/******************************************
 *                  CHAT                  *
 ******************************************/


/**
 * Module dependencies.
 */



exports.configure = function(sio) {

  var chat = sio.of('/chat');

  chat.on('connection', function(socket) {

    var hs = socket.handshake;
    console.log('A socket with sessionId '+hs.sessionId+' connected.');

    socket.json.emit('list', users);
    socket.broadcast.json.emit('enter', hs.session.name);

    socket.on('message', function(message) {
      socket.broadcast.json.emit({
        id: hs.session.uid,
        message: message,
        time: new Date
      });
    });

    socket.on('disconnect', function(){
      console.log('A socket with sessionId ' + hs.sessionId + ' disconnected.');
    });

  });

}
