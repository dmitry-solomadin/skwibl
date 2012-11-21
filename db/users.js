/******************************************
 *             USER MANAGEMENT            *
 ******************************************/


/**
 * Module dependencies.
 */

var _ = require('underscore');

var tools = require('../tools');

exports.setUp = function(client, db) {

  var mod = {};

  mod.persist = function(user, fn) {
    var emails = user.emails
      , id = user.id;
    client.hdel('users:' + id, 'hash');
    client.del('hashes:' + user.hash + ':uid');
    db.users.setProperties(user.id, {
      status: 'registred'
    } ,function(err, val) {
      return tools.asyncOpt(fn, err, user);
    });
  }

  mod.add = function(user, name, emails, fn) {
    client.incr('users:next', function(err, val) {
      if(!err) {
        user.id = val + '';
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
            return tools.asyncOpt(fn, err, null);
          }
          user.name = purifiedName;
          user.emails = emails;
          return tools.asyncOpt(fn, null, user);
        });
      }
      return tools.asyncOpt(fn, err, null);
    });
  };

  mod.restore = function(id, fn) {
    // Get contacts list
    client.smembers('users:' + id + ':contacts', function(err, array) {
      if(!err) {
        array.forEach(function(cid) {
          // Add user from contacts' lists
          client.sadd('users:' + cid + ':contacts');
        });
      }
    });
    // Get unconfirmed contacts list
    client.smembers('users:' + id + 'unconfirmed', function(err, array) {
      if(!err) {
        array.forEach(function(cid) {
          // Add user from contacts' requests
          client.sadd('users:' + cid + ':requests');
        });
      }
    });
    // Set status to registred
    return client.hset('users:' + id + ':emails' , 'status', 'registred', fn);
  };

  mod.delete = function(id, fn) {
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

  mod.findById = function(id, fn) {
    client.hgetall('users:' + id, function (err, user) {
      if(err || !user) {
        return tools.asyncOpt(fn, err, null);
      }
      client.smembers('users:' + id + ':emails',  function(err, emails) {
        if(err) {
          return tools.asyncOpt(fn, new Error('User ' + id + ' have no emails'));
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
            return tools.asyncOpt(fn, null, user);
          });
        });
      });
    });
  };

  mod.findByEmail = function(email, fn) {
    client.get('emails:' + email + ':uid', function(err, val) {
      if(err) {
        return tools.asyncOpt(fn, err, null);
      }
      return db.users.findById(val, fn);
    });
  };

  mod.findByEmails = function(emails, fn) {
    client.mget(_.pluck(emails, 'value').map(tools.emailUid), function(err, array) {
      if(!err && array) {
        for(var i = 0, len = array.length; i < len; i++) {
          var id = array[i];
          if(id) {
            return db.users.findById(id, fn);
          }
        }
      }
      return tools.asyncOpt(fn, err, null);
    });
  };

  mod.findByHash = function(hash, fn) {
    client.get('hashes:' + hash + ':uid', function(err, val) {
      if(!err && val) {
        return db.users.findById(val, fn);
      }
      return tools.asyncOpt(fn, err, null);
    });
  };

  mod.setProperties = function(id, properties, fn) {
    var purifiedProp = tools.purify(properties);
    return client.hmset('users:' + id ,purifiedProp, fn);
  };

  mod.setName = function(id, name, fn) {
    var purifiedName = tools.purify(name);
    return client.hmset('users:' + id + ':name', purifiedName, fn);
  };

  mod.addEmails = function(id, emails, fn) {
    var values = _.pluck(emails, 'value');
    client.sadd('users:' + id + ':emails' , values);
    values.forEach(function(value, index) {
      client.mset('emails:' + value + ':uid', id, 'emails:' + value + ':type', emails[index].type);
    });
    return tools.asyncOpt(fn, null, values);
  };

  return mod;

};
