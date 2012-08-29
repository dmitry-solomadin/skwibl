/******************************************
 *             USER MANAGEMENT            *
 ******************************************/


/**
 * Module dependencies.
 */

var tools = require('../tools/tools');

exports.setUp = function(client) {

  var mod = {};

  mod.findUserById = function(id, fn) {
    client.hgetall('users:' + id, function (err, user) {
      if(err || !user) {
        return process.nextTick(function () {
          fn(err, null);
        });
      }
      client.smembers('users:' + id + ':emails',  function(err, emails) {
        if(err) {
          return process.nextTick(function () {
            fn(new Error('User ' + id + ' have no emails'));
          });
        }
        client.mget(emails.map(tools.emailType), function(err, array) {
          if(array && array.length) {
            var types = array;
          }
          client.hgetall('users:' + id + ':name', function(err, name) {
            var umails = [];
            for(var i = 0, len = emails.length; i < len; i++) {
              umails.push({
                value: emails[i]
              , type: types[i]
              });
            }
            user.emails = umails;
            user.name = name;
            return process.nextTick(function () {
              return fn(null, user);
            });
          });
        });
      });
    });
  };

  mod.findUserByMail = function(email, fn) {
    var me = this;
    client.get('emails:' + email + ':uid', function(err, val) {
      if(err) {
        return process.nextTick(function () {
          fn(null, null);
        });
      }
      return me.findUserById(val, fn);
    });
  };

  mod.findUserByMails = function(emails, fn) {
    var me = this;
    client.mget(emails.map(tools.getValue).map(tools.emailUid), function(err, array) {
      if(!err && array) {
        for(var i = 0, len = array.length; i < len; i++) {
          var id = array[i];
          if(id) {
            return me.findUserById(id, fn)
          }
        }
      }
      return process.nextTick(function () {
        fn(null, null);
      });
    });
  };

  mod.findUserByHash = function(hash, fn) {
    var me = this;
    client.get('hashes:' + hash + ':uid', function(err, val) {
      if(!err && val) {
        return me.findUserById(val, fn);
      }
      return process.nextTick(function () {
        fn(null, null);
      });
    });
  };

  mod.setUserProperties = function(id, properties, fn) {
    client.exists('users:' + id, function(err, val) {
      if(!err && val) {
        return client.hmset('users:' + id ,properties, function(err, val) {
          return process.nextTick(function () {
            fn(null);
          });
        });
      }
      return process.nextTick(function () {
        fn(new Error('User ' + id + ' does not exist'));
      });
    });
  };

  mod.addUserMail = function(id, email, fn) {
    client.exists('users:' + id, function(err, val) {
      var value = email.value;
      if(!err && val) {
        client.sadd('users:' + id + ':emails' , value);
        return client.mset('emails:' + value + ':uid', id, 'emails:' + value + ':type', email.type, fn);
      }
      return process.nextTick(function () {
        fn(new Error('User ' + id + ' does not exist'));
      });
    });
  };

  return mod;

};
