/******************************************
 *            LOGIN & REGISTER            *
 ******************************************/


/**
 * Module dependencies.
 */

var _ = require('underscore');

var smtp = require('../smtp/smtp')
//   , cfg = require('../config')
  , tools = require('../tools/tools');

exports.setUp = function(client) {

  var mod = {};

  mod.persistUser = function(user, fn) {
    var emails = user.emails
      , id = user.id;
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
    client.incr('users:next', function(err, val) {
      if(!err) {
        user.id = val;
        user.email = emails[0].value;
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
        if(user.hash) {
          client.set('hashes:' + user.hash + ':uid', val);
        }
        client.hmset('users:' + val, user);
        var purifiedName = tools.purify(name);
        if(purifiedName) {
          client.hmset('users:' + val + ':name', purifiedName);
        }
        client.sadd('users:' + val + ':emails', umails);
        client.mset(emailtypes);
        return client.mset(emailuid, function(err, results) {
          if(err) {
            return process.nextTick(function () {
              fn(err, null);
            });
          }
          user.name = purifiedName;
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
    // Get contacts list
    client.smembers('users:' + id + ':contacts', function(err, array) {
      if(!err) {
        val.forEach(function(cid) {
          // Add user from contacts' lists
          client.sadd('users:' + cid + ':contacts');
        });
      }
    });
    // Get unconfirmed contacts list
    client.smembers('users:' + id + 'unconfirmed', function(err, array) {
      if(!err) {
        val.forEach(function(cid) {
          // Add user from contacts' requests
          client.sadd('users:' + cid + ':requests');
        });
      }
    });
    // Set status to registred
    return client.hset('users:' + id + ':emails' , 'status', 'registred', fn);
  };

  mod.delUser = function(id, fn) {
    // Get contacts list
    client.smembers('users:' + id + ':contacts', function(err, array) {
      if(!err) {
        array.forEach(function(cid) {
          // Delete user from contacts' lists
          client.srem('users:' + cid + ':contacts');
        });
      }
    });
    // Get unconfirmed contacts list
    client.smembers('users:' + id + 'unconfirmed', function(err, array) {
      if(!err) {
        array.forEach(function(cid) {
          // Delete user from contacts' requests
          client.srem('users:' + cid + ':requests');
        });
      }
    });
    // Set status to deleted
    return client.hset('users:' + id + ':emails' , 'status', 'deleted', fn);
  };

  mod.findUserByMailsOrCreate = function(profile, fn) {
    var emails = profile.emails
      , me = this;
    return this.findUserByMails(emails, function (err, user) {
      if(!user) {
        var email = emails[0].value
          , password = tools.genPass();
        return me.addUser({
          displayName: profile.displayName
        , providerId: profile.id
        , password: password
        , picture: profile._json.picture
        , status: 'registred'
        , provider: profile.provider
        }, profile.name, emails, function(err, user){
          if(user) {
            return smtp.sendRegMail(user, fn);
          }
          return process.nextTick(function () {
            fn(err, user);
          });
        });
      }
      if(!user.picture) {
        user.picture = profile._json.picture;
        this.setUserProperties(user.id, {
          picture: user.picture
        });
      }
      if(!_.isEqual(user.name, profile.name)) {
        user.name = _.extend(profile.name, user.name);
        me.setUserName(user.id, user.name);
      }
      var diff = _.difference(profile.emails, user.emails)
      if(diff.length) {
        user.emails.concat(diff);
        me.addUserEmails(user.id, user.emails);
      }
      if(user.status === 'unconfirmed') {
        return me.persistUser(user, fn);
      }
      if(user.status === 'deleted') {
        return me.restoreUser(user, fn);
      }
      return process.nextTick(function () {
        fn(err, user);
      });
    });
  };

  return mod;

};
