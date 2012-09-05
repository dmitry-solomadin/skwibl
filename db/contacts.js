/******************************************
 *           CONTACTS MANAGEMENT          *
 ******************************************/


/**
 * Module dependencies.
 */

var smtp = require('../smtp/smtp')
  , tools = require('../tools/tools');

exports.setUp = function(client, db) {

  var mod = {};

  mod.getInfo = function(id, confirmed, fn) {
    client.hmget('users:' + id, 'provider', 'providerId', 'displayName', 'picture', function(err,array) {
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

  mod.getField = function(id, field, fn) {
    client.smembers('users:' + id + field, function(err, array) {
      if(!err && array) {
        var leftToProcess = array.length - 1
          , confirmed = field === ':contacts'
          , contacts = [];
        for(var i = 0, len = array.length; i < len; i++) {
          (function(cid) {
            process.nextTick(function() {
              db.contacts.getInfo(cid, confirmed, function(err, contact) {
                if(err) {
                  return process.nextTick(function() {
                    fn(err, []);
                  });
                }
                contacts.push(contact);
                if(leftToProcess-- === 0) {
                  return process.nextTick(function() {
                    fn(null, contacts);
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

  mod.get = function(id, fn) {
    db.contacts.getField(id, ':contacts', function(err, contacts) {
      if(err) {
        return process.nextTick(function() {
          fn(err, []);
        });
      }
      return db.contacts.getField(id, ':unconfirmed', function(err, unconfirmed) {
        if(err) {
          return process.nextTick(function() {
            fn(err, contacts);
          });
        }
        return process.nextTick(function() {
          //TODO change to async loop
          fn(err, contacts.concat(unconfirmed));
        });
      });
    });
  };

  mod.isContact = function(id, cid, pid, fn) {
    //Get user projects
    client.smembers('users:' + id + ':projects', function(err, array) {
      if(!err && array) {
        var leftToProcess = array.length;
        for(var i = 0, len = array.length; i < len; i++) {
          (function(project) {
            if(array[i] !== pid) {
              //Check if client belongs to another project
              client.sismember('projects:' + project + ':users', function(err, val) {
                if(!err && val) {
                  return process.nextTick(function() {
                    fn(null, true);
                  });
                }
                if(--leftToProcess === 0) {
                  return process.nextTick(function() {
                    fn(null, false);
                  });
                }
              });
            }
          })(array[i]);
        }
      }
    });
  };

  mod.recalculate = function(id, contacts, pid, fn) {
    contacts.forEach(function(cid) {
      db.contacts.isContact(id, cid, pid, function(err, val) {
        if(err || !val) {
          client.srem('users:' + id + ':contacts', cid);
          client.srem('users:' + cid + ':contacts', id);
        }
      });
    });
    return process.nextTick(function() {
      fn(err, val);
    });
  };

//   mod.inviteEmailUserContact = function(id, email, fn) {
//     db.users.findByEmail(email, function(err, contact) {
//       if(err) {
//         return process.nextTick(function () {
//           fn(err);
//         });
//       }
//       if(contact) {
//         return db.users.addContact(id, contact.id, fn);
//       }
//       var hash = tools.hash(email)
//       , password = tools.genPass();
//       return db.users.add({
//         hash: hash,
//         password: password,
//         status: 'unconfirmed',
//         provider: 'local'
//       }, null, [{
//         value: email,
//         type: 'main'
//       }], function(err, contact) {
//         if (err) {
//           return process.nextTick(function () {
//             fn(err);
//           });
//         }
//         if (!contact) {
//           return process.nextTick(function () {
//             fn(new Error('Can not create user.'));
//           });
//         }
//         client.sadd('users:' + id + ':unconfirmed', contact.id);
//         client.sadd('users:' + contact.id + ':requests', id);
//         return db.users.findById(id, function(err, user) {
//           return smtp.regPropose(user, contact, hash, fn);
//         });
//         //       return db.expireUser(contact, db.users.findById(id, function(err, user) {
//         //         return smtp.regPropose(user, contact, hash, fn);
//         //       }));
//       });
//     });
//   };
//
//   mod.confirmUserContact = function(id, cid, accept, fn) {
//     if(accept) {
//       client.smove('users:' + id + ':requests', 'users:' + id + ':contacts', cid);
//       return client.smove('users:' + cid + ':unconfirmed', 'users:' + cid + ':contacts', id, fn);
//       // TODO send notification to a new fried
//     }
//     client.srem('users:' + id + ':requests', cid);
//     return client.srem('users:' + cid + 'unconfirmed', id, fn);
//   };

  return mod;

};
