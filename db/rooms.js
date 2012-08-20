/******************************************
 *             ROOM MANAGEMENT            *
 ******************************************/


exports.setUp = function(client) {

  var mod = {};

  mod.addUserToRoomFriends = function(id, roomId, fn) {
    //Add user as a friend to all room members
    client.smembers('rooms:' + roomId + 'friends', function(err, array) {
      if(!err && array) {
        var leftToProcess = array.length - 1;
        for(var i = 0, len = array.length; i < len; i++) {
          (function(friendId) {
            process.nextTick(function() {
              client.sadd('users:' + id + ':fiends', friendId);
              client.sadd('users:' + friendId + ':fiends', id);
              if(leftToProcess-- === 0) {
                return process.nextTick(function() {
                  fn(err);
                });
              }
            });
          })(array[i])
        }
      }
      fn(err);
    });
  };

  mod.createRoom = function(id, name, friendIds, fn) {
    client.incr('global:nextRoomId', function(err, val) {
      if(!err) {
        roomId = val;
        client.set('rooms:' + roomId + ':name', name);
        client.set('rooms:' + roomId + ':friends', friendIds);
        //TODO send notification to all friends except creator
      }
      return process.nextTick(function () {
        fn(err, null);
      });
    });
  };

  mod.deleteRoom = function(id, roomId, fn) {
    client.srem('rooms:' + roomId + ':friends', id);
    client.scard('rooms:' + roomId + ':friends', function(err, val) {
      if(!err && !val) {
        return client.del('rooms:' + roomId, fn(err, value));
      }
      //TODO send notification to all friends except id
      return process.nextTick(function() {
        fn(err, val);
      });
    });
  };

  mod.addUserToRoom = function(id, roomId, fn) {
    var me = this;
    //Check if user exists
    return client.exists('users:' + id, function(err, val) {
      if(!err && val) {
        return me.addUserToRoomFriends(id, roomId, function(err) {
          return me.addUserToRoomFriends(id, roomId, function() {
            return client.sadd('rooms:' + roomId + ':friends', id, fn);
          });
        });
        //TODO send notification to all friends except id
      }
      return process.nextTick(function() {
        fn(err);
      });
    });
  };

  mod.inviteUserToRoom = function(id, roomId, providerId, provider, fn) {};

  mod.inviteEmailUserToRoom = function(id, roomId, email, fn) {};

  mod.inviteLinkUserToRoom = function(id, roomId, fn) {};

  return mod;

};
