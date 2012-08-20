/******************************************
 *           FRIENDS MANAGEMENT           *
 ******************************************/


/**
 * Module dependencies.
 */

var smtp = require('../smtp/smtp')
  , tools = require('../tools/tools');

exports.setUp = function(client) {

  var mod = {};

  mod.getFriendInfo = function(id, confirmed, fn) {
    client.hmget('users:' + id, 'provider', 'providerId', 'displayName', 'avatar', function(err,array) {
      if(err) {
        return process.nextTick(function() {
          fn(err, array);
        });
      }
      array.push(confirmed);
      return process.nextTick(function() {
        fn(err, array);
      });
    });
  };

  mod.getUserFriendsField = function(id, field, fn) {
    var me = this;
    client.smembers('users:' + id + field, function(err, array) {
      if(!err && array) {
        var leftToProcess = array.length - 1
        , confirmed = field === ':friends'
        , friends = [];
        for(var i = 0, len = array.length; i < len; i++) {
          (function(friendId) {
            process.nextTick(function() {
              me.getFriendInfo(friendId, confirmed, function(err, friend) {
                if(err) {
                  return process.nextTick(function() {
                    fn(err, []);
                  });
                }
                friends.push(friend);
                if(leftToProcess-- === 0) {
                  return process.nextTick(function() {
                    fn(null, friends);
                  });
                }
              });
            });
          })(array[i]);
        }
      }
      return process.nextTick(function() {
        fn(err, []);
      });
    });
  };

  mod.getUserFriends = function(id, fn) {
    var me = this;
    this.getUserFriendsField(id, ':friends', function(err, friends) {
      if(err) {
        return process.nextTick(function() {
          fn(err, []);
        });
      }
      return me.getUserFriendsField(id, ':friendsunconfirmed', function(err, unconfirmed) {
        if(err) {
          return process.nextTick(function() {
            fn(err, friends);
          });
        }
        return process.nextTick(function() {
          //TODO change to async loop
          fn(err, friends.concat(unconfirmed));
        });
      });
    });
  };

  mod.addUserFriend = function(id, friendId, fn) {
    // Check if friend exists
    return client.exists('users:' + friendId, function(err, val) {
      if(!err && val) {
        // Add friend to unconfirmed
        return client.sadd('users:' + id + ':friendsunconfirmed', friendId, function(err, val) {
          if(!err) {
            // Add friendrequest for the friend
            return client.sadd('users:' + friendId + ':friendrequests', id, fn);
          }
          return process.nextTick(function () {
            fn(new Error('Can not add user' + friendId + 'as a fiend'));
          });
        });
      }
      return process.nextTick(function () {
        fn(new Error('User ' + friendId + ' does not exist'));
      });
    });
  };

  mod.deleteUserFriend = function(id, friendId, fn) {
    // Delete User from friend list
    client.srem('users:' + friendId + ':friends', id);
    // Delete User from friendrequests
    client.srem('users:' + friendId + ':friendrequests', id);
    // Delete Friend from user list
    client.srem('users:' + id + ':friends', friendId);
    // Delete Friend from unconfirmed
    client.srem('users:' + id + ':friendsunconfirmed', friendId, fn);
  };

  mod.inviteUserFriend = function(id, providerId, provider, fn) {
    // TODO Invite new Fiend from Social networks
  };

  mod.inviteEmailUserFriend = function(id, email, fn) {
    var me = this;
    this.findUserByMail(email, function(err, friend) {
      if(err) {
        return process.nextTick(function () {
          fn(err);
        });
      }
      if(friend) {
        return me.addUserFriend(id, friend.id, fn);
      }
      var hash = tools.hash(email)
      , password = tools.genPass();
      return me.addUser({
        hash: hash,
        password: password,
        status: 'unconfirmed',
        provider: 'local'
      }, null, [{
        value: email,
        type: 'main'
      }], function(err, friend) {
        if (err) {
          return process.nextTick(function () {
            fn(err);
          });
        }
        if (!friend) {
          return process.nextTick(function () {
            fn(new Error('Can not create user.'));
          });
        }
        client.sadd('users:' + id + ':friendsunconfirmed', friend.id);
        client.sadd('users:' + friend.id + ':friendrequests', id);
        return me.findUserById(id, function(err, user) {
          return smtp.regPropose(user, friend, hash, fn);
        });
        //       return me.expireUser(friend, me.findUserById(id, function(err, user) {
        //         return smtp.regPropose(user, friend, hash, fn);
        //       }));
      });
    });
  };

  mod.inviteLinkUserFriend = function(id, fn) {
    //TODO generate link for a user
  };

  mod.confirmUserFriend = function(id, friendId, accept, fn) {
    client.srem('users:' + id + ':friendrequests', friendId);
    if(accept) {
      client.smove('users:' + friendId + ':friendsunconfirmed', 'users:' + fiendId + 'friends', id, fn);
      // TODO send notification to a new fried
    } else {
      client.srem('users:' + friendId + 'friendsunconfirmed', id, fn);
    }
  };

  return mod;

};
