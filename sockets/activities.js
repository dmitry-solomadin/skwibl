/******************************************
 *               ACTIVITIES               *
 ******************************************/


/**
 * Module dependencies.
 */



exports.configure = function(sio) {

  var activities = sio.of('/activities');

  activities.on('connection', function(socket) {

    var hs = socket.handshake;
    console.log('A socket with sessionId '+hs.sessionId+' connected.');

    socket.on('disconnect', function(){
      console.log('A socket with sessionId ' + hs.sessionId + ' disconnected.');
    });

  });

}
