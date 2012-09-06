/******************************************
 *           CONTACTS MANAGEMENT          *
 ******************************************/


/**
 * Module dependencies.
 */

var smtp = require('../smtp')
  , tools = require('../tools');

exports.setUp = function(client, db) {

  var mod = {};

  mod.getInfo = function(id, fn) {
    client.hmget('users:' + id, 'provider', 'providerId', 'displayName', 'picture', function(err,array) {
      if(err) {
        return tools.asyncOpt(fn, err, array);
      }
      return tools.asyncOpt(fn, err, array);
    });
  };

  mod.getField = function(id, field, fn) {
    client.smembers('users:' + id + field, function(err, array) {
      if(!err && array) {
        var contacts = [];
        tools.asyncParallel(array, function(left, cid) {
          db.contacts.getInfo(cid, function(err, contact) {
            if(err) {
              return tools.asyncOpt(fn, err, []);
            }
            contacts.push(contact);
            tools.asyncDone(left, function() {
              fn(null, contacts);
            });
          });
        });
      }
      return tools.asyncOpt(fn, err, []);
    });
  };

  mod.get = function(id, fn) {
    db.contacts.getField(id, ':contacts', function(err, contacts) {
      return tools.asyncOpt(fn, err, contacts);
    });
  };

  mod.isContact = function(id, cid, pid, fn) {
    //Get user projects
    client.smembers('users:' + id + ':projects', function(err, array) {
      if(!err && array) {
        tools.asyncParallel(array, function(left, project) {
          if(array[i] !== pid) {
            //Check if client belongs to another project
            client.sismember('projects:' + project + ':users', function(err, val) {
              if(!err && val) {
                return tools.asyncOpt(fn, null, true);
              }
              tools.asyncDone(left, function() {
                fn(null, false);
              });
            });
          }
        });
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
    return tools.asyncOpt(fn, err, val);
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
