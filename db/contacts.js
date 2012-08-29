/******************************************
 *           CONTACTS MANAGEMENT          *
 ******************************************/


/**
 * Module dependencies.
 */

var smtp = require('../smtp/smtp')
  , tools = require('../tools/tools');

exports.setUp = function(client) {

  var mod = {};

  mod.getContactInfo = function(id, confirmed, fn) {
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

  mod.getUserContactField = function(id, field, fn) {
    var me = this;
    client.smembers('users:' + id + field, function(err, array) {
      if(!err && array) {
        var leftToProcess = array.length - 1
        , confirmed = field === ':contacts'
        , contacts = [];
        for(var i = 0, len = array.length; i < len; i++) {
          (function(cid) {
            process.nextTick(function() {
              me.getContactInfo(cid, confirmed, function(err, contact) {
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

  mod.getUserContacts = function(id, fn) {
    var me = this;
    this.getUserContactField(id, ':contacts', function(err, contacts) {
      if(err) {
        return process.nextTick(function() {
          fn(err, []);
        });
      }
      return me.getUserContactField(id, ':unconfirmed', function(err, unconfirmed) {
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

  mod.addUserContact = function(id, cid, fn) {
    // Check if contact exists
    return client.exists('users:' + cid, function(err, val) {
      if(!err && val) {
        // Add contact to unconfirmed
        return client.sadd('users:' + id + ':unconfirmed', cid, function(err, val) {
          if(!err) {
            // Add request for the contact
            return client.sadd('users:' + cid + ':requests', id, fn);
          }
          return process.nextTick(function () {
            fn(new Error('Can not add user' + cid + 'as a contact'));
          });
        });
      }
      return process.nextTick(function () {
        fn(new Error('User ' + cid + ' does not exist'));
      });
    });
  };

  mod.deleteUserContact = function(id, cid, fn) {
    // Delete User from contact list
    client.srem('users:' + cid + ':contacts', id);
    // Delete User from requests
    client.srem('users:' + cid + ':requests', id);
    // Delete Contact from user list
    client.srem('users:' + id + ':contacts', cid);
    // Delete Contact from unconfirmed
    client.srem('users:' + id + ':unconfirmed', cid, fn);
  };

  mod.inviteUserContact = function(id, providerId, provider, fn) {
    // TODO Invite new Fiend from Social networks
  };

  mod.inviteEmailUserContact = function(id, email, fn) {
    var me = this;
    this.findUserByMail(email, function(err, contact) {
      if(err) {
        return process.nextTick(function () {
          fn(err);
        });
      }
      if(contact) {
        return me.addUserContact(id, contact.id, fn);
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
      }], function(err, contact) {
        if (err) {
          return process.nextTick(function () {
            fn(err);
          });
        }
        if (!contact) {
          return process.nextTick(function () {
            fn(new Error('Can not create user.'));
          });
        }
        client.sadd('users:' + id + ':unconfirmed', contact.id);
        client.sadd('users:' + contact.id + ':requests', id);
        return me.findUserById(id, function(err, user) {
          return smtp.regPropose(user, contact, hash, fn);
        });
        //       return me.expireUser(contact, me.findUserById(id, function(err, user) {
        //         return smtp.regPropose(user, contact, hash, fn);
        //       }));
      });
    });
  };

  mod.inviteLinkUserContact = function(id, fn) {
    //TODO generate link for a user
  };

  mod.confirmUserContact = function(id, cid, accept, fn) {
    if(accept) {
      client.smove('users:' + id + ':requests', 'users:' + id + ':contacts', cid);
      return client.smove('users:' + cid + ':unconfirmed', 'users:' + cid + ':contacts', id, fn);
      // TODO send notification to a new fried
    }
    client.srem('users:' + id + ':requests', cid);
    return client.srem('users:' + cid + 'unconfirmed', id, fn);
  };

  return mod;

};
