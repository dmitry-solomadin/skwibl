/******************************************
 *          MIDDLEWARE FUNCTIONS          *
 ******************************************/


exports.setUp = function(client) {

  var mod = {};

  mod.isUserRoomMember = function(id, roomId, fn) {
    client.sismember('rooms:' + roomId + ':friends', fn);
  };

  return mod;

};
