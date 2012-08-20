/******************************************
 *            LOGIN & REGISTER            *
 ******************************************/


/**
 * Module dependencies.
 */

var smtp = require('../smtp/smtp')
//   , cfg = require('../config')
  , tools = require('../tools/tools');

exports.setUp = function(client) {

  var mod = {};

//   mod.expireUser = function(user, fn) {
//     var emails = user.emails
//       , id = user.id;
//     client.expire('users:' + id, cfg.CONFIRM_EXPIRE);
//     client.expire('users:' + id + ':emails', cfg.CONFIRM_EXPIRE);
//     for(var i = 0, len = emails.length; i < len; i++) {
//       var email = emails[i].value;
//       client.expire('emails:' + email + ':type', cfg.CONFIRM_EXPIRE);
//       client.expire('emails:' + email + ':uid', cfg.CONFIRM_EXPIRE);
//     }
//     client.expire('users:' + id + ':friendrequests', cfg.CONFIRM_EXPIRE);
//     //TODO delete unconfirmed friends if user expire
//     client.expire('hashes:' + user.hash + ':uid', cfg.CONFIRM_EXPIRE, fn);
//   };

  mod.persistUser = function(user, fn) {
    var emails = user.emails
      , id = user.id;
    //   client.persist('users:' + id);
    //   client.persist('users:' + id + ':emails');
    //   for(var i = 0, len = emails.length; i < len; i++) {
      //     var email = emails[i].value;
    //     client.persist('emails:' + email + ':type');
    //     client.persist('emails:' + email + ':uid');
    //   }
    client.hdel('users:' + id, 'hash');
    client.del('hashes:' + user.hash + ':uid');
    this.setUserProperties(user.id, {
      status: 'registred'
    } ,function(err, val) {
      return process.nextTick(function () {
        fn(err, user);
      });
    });
  }

  mod.addUser = function(user, name, emails, fn) {
    client.incr('global:nextUserId', function(err, val) {
      if(!err) {
        user.id = val;
        if(user.provider === 'local') {
          user.providerId = val;
        }
        var umails = []
        , emailtypes = []
        , emailuid = [];
        for(var i = 0, len = emails.length; i < len; i++) {
          var email = emails[i].value;
          umails.push(email);
          emailtypes.push('emails:' + email + ':type');
          emailtypes.push(emails[i].type);
          emailuid.push('emails:' + email + ':uid');
          emailuid.push(val);
        }
        //TODO remove multi
        var multi = client.multi();
        if(user.hash) {
          multi.set('hashes:' + user.hash + ':uid', val);
        }
        multi.hmset('users:' + val, user);
        multi.lpush('users:' + val + ':emails', umails);
        multi.mset(emailtypes);
        multi.mset(emailuid);
        return multi.exec(function(err, results) {
          if(err) {
            return process.nextTick(function () {
              fn(err, null);
            });
          }
          user.name = name;
          user.emails = emails;
          return process.nextTick(function () {
            fn(null, user);
          });
        });
      }
      return process.nextTick(function () {
        fn(err, null);
      });
    });
  };

  mod.restoreUser = function(id, fn) {
    // If user exists
    client.exists('users:' + id, function(err, val) {
      if(!err && val) {
        // Get friends list
        client.smembers('users:' + id + 'friends', function(err, array) {
          if(!err) {
            val.forEach(function(friendId) {
              // Add user from friends' lists
              client.sadd('users:' + friendId + ':friends');
            });
          }
        });
        // Get unconfirmed friends list
        client.smembers('users:' + id + 'friendsunconfirmed', function(err, array) {
          if(!err) {
            val.forEach(function(friendId) {
              // Add user from friends' requests
              client.sadd('users:' + friendId + ':friendrequests');
            });
          }
        });
        // Set status to registred
        return client.hset('users:' + id + ':emails' , 'status', 'registred', fn);
      }
      return process.nextTick(function () {
        fn(new Error('User ' + id + ' does not exist'));
      });
    });
  };

  mod.delUser = function(id, fn) {
    // If user exists
    client.exists('users:' + id, function(err, val) {
      if(!err && val) {
        // Get friends list
        client.smembers('users:' + id + 'friends', function(err, array) {
          if(!err) {
            val.forEach(function(friendId) {
              // Delete user from friends' lists
              client.srem('users:' + friendId + ':friends');
            });
          }
        });
        // Get unconfirmed friends list
        client.smembers('users:' + id + 'friendsunconfirmed', function(err, array) {
          if(!err) {
            val.forEach(function(friendId) {
              // Delete user from friends' requests
              client.srem('users:' + friendId + ':friendrequests');
            });
          }
        });
        // Set status to deleted
        return client.hset('users:' + id + ':emails' , 'status', 'deleted', fn);
      }
      return process.nextTick(function () {
        fn(new Error('User ' + id + ' does not exist'));
      });
    });
  };

  mod.findUserByMailsOrCreate = function(profile, fn) {
    var emails = profile.emails
    , me = this;
    return this.findUserByMails(emails, function (err, user) {
      if(!user) {
        var email = emails[0].value
        , password = tools.genPass();
        return me.addUser({
          displayName: profile.displayName,
          providerId: profile.id,
          password: password,
          status: 'registred',
          provider: profile.provider
        }, profile.name, emails, function(err, user){
          if(user) {
            return smtp.sendRegMail(user, fn);
          }
          return process.nextTick(function () {
            fn(err, user);
          });
        });
      }
      if(user.status === 'unconfirmed') {
        return me.persistUser(user, fn);
      }
      return process.nextTick(function () {
        fn(err, user);
      });
    });
  };

  return mod;

};
