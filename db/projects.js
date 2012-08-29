/******************************************
 *           PROJECTS MANAGEMENT          *
 ******************************************/


exports.setUp = function(client) {

  var mod = {};

  mod.addUserToProject = function(id, rid, fn) {
    //Add user as a contact to all project members
    client.smembers('projects:' + rid + ':users', function(err, array) {
      if(!err && array) {
        var leftToProcess = array.length - 1;
        for(var i = 0, len = array.length; i < len; i++) {
          (function(cid) {
            process.nextTick(function() {
              client.sadd('users:' + id + ':contacts', cid);
              client.sadd('users:' + cid + ':contacts', id);
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

  mod.createProject = function(id, name, cids, fn) {
    client.incr('global:nextProjectId', function(err, val) {
      if(!err) {
        rid = val;
        client.set('projects:' + rid + ':name', name);
        client.set('projects:' + rid + ':users', cids);
        //TODO send notification to all users except creator
      }
      return process.nextTick(function () {
        fn(err, null);
      });
    });
  };

  mod.deleteProject = function(id, rid, fn) {
    client.srem('projects:' + rid + ':users', id);
    client.scard('projects:' + rid + ':users', function(err, val) {
      if(!err && !val) {
        return client.del('projects:' + rid, fn(err, value));
      }
      //TODO send notification to all contacts except id
      return process.nextTick(function() {
        fn(err, val);
      });
    });
  };

  mod.addUserToProject = function(id, rid, fn) {
    var me = this;
    //Check if user exists
    return client.exists('users:' + id, function(err, val) {
      if(!err && val) {
        return me.addUserToProject(id, rid, function(err) {
          return me.addUserToProject(id, rid, function() {
            return client.sadd('projects:' + rid + ':users', id, fn);
          });
        });
        //TODO send notification to all contacts except id
      }
      return process.nextTick(function() {
        fn(err);
      });
    });
  };

  mod.inviteUserToProject = function(id, rid, providerId, provider, fn) {};

  mod.inviteEmailUserToProject = function(id, rid, email, fn) {};

  mod.inviteLinkUserToProject = function(id, rid, fn) {};

  return mod;

};
