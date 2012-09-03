/******************************************
 *           PROJECTS MANAGEMENT          *
 ******************************************/


/**
 * Module dependencies.
 */

var _ = require('underscore');

var tools = require('../tools/tools');

exports.setUp = function(client) {

  var mod = {};

  mod.getUserProjects = function(id, fn) {};

  mod.getProjectData = function(pid, id, fn) {}

  mod.addProject = function(uid, name, fn) {
    client.incr('projects:next', function(err, val) {
      if(!err) {
        var project = {};
        project.name = name;
        project.owner = uid;
        project.start = new Date;
        project.status = 'new';
        client.hmset('projects:' + val, project);
        client.sadd('projects:' + val + ':users', uid);
        return process.nextTick(function() {
          fn(null, project);
        });
      }
      return process.nextTick(function() {
        fn(err, null);
      });
    });
  };

  mod.setProjectProperties = function(pid, properties, fn) {
    var purifiedProp = tools.purify(properties);
    return client.hmset('projects:' + pid, purifiedProp, function(err, val) {
      return process.nextTick(function() {
        fn(null);
      });
    });
  };

  mod.inviteUserToProject = function(pid, id, fn) {
    //Check if user exists
    return client.exists('users:' + id, function(err, val) {
      if(!err && val) {
        client.sadd('projects:' + pid + ':unconfirmed', id);
        //TODO Send invitation to user
      }
      return process.nextTick(function() {
        fn(err);
      });
    });
  };

  mod.inviteSocialUserToProject = function(pid, provider, providerId, fn) {};

  mod.inviteEmailUserToProject = function(pid, email, fn) {};

  mod.inviteLinkUserToProject = function(pid, fn) {};

  mod.confirmUserToProject = function(pid, id, fn) {
    //Get project members
    client.smembers('projects:' + pid + ':users', function(err, array) {
      if(!err && array) {
        var leftToProcess = array.length - 1;
        for(var i = 0, len = array.length; i < len; i++) {
          (function(cid) {
            process.nextTick(function() {
              //Add the user as a contact to all project members
              client.sadd('users:' + cid + ':contacts', id);
              //And vise-versa
              client.sadd('users:' + id + ':contacts', cid);
              if(leftToProcess-- === 0) {
                return process.nextTick(function() {
                  //Add the user to the project
                  client.smove('projects:' + pid + ':unconfirmed', 'projects:' + pid + ':users', id);
                  //Add the project to the user
                  client.sadd('users:' + id + ':projects', pid);
                  fn(null);
                });
              }
            });
          })(array[i])
        }
      }
      fn(err);
    });
  };

  mod.removeUserFromProject = function(pid, id, fn) {
    var me = this;
    this.isUserProjectMember(id, pid, function(err, val) {
      if(!err && val) {
        //Remove project from user projects
        client.srem('users:' + id + ':projects', pid);
        //Remove user from project members
        client.srem('projects:' + pid + ':users', id, function(err) {
          //Get project members
          client.smembers('projects:' + pid + ':users', function(err, array) {
            if(!err && array) {
              me.recalculateUserContacts(id, array, pid);
              var leftToProcess = array.length - 1;
              for(var i = 0, len = array.length; i < len; i++) {
                (function(cid) {
                  process.nextTick(function() {
                    //Recalculate member contacts
                    me.recalculateUserContacts(cid, [id], pid);
                    if(leftToProcess-- === 0) {
                      return process.nextTick(function() {
                        fn(null);
                      });
                    }
                  });
                })(array[i])
              }
            }
            fn(err);
          });
        });
      }
      return fn(new Error('user ' + id + ' does not belong to project ' + pid));
    });
  };

  return mod;

};
