/******************************************
 *           PROJECTS MANAGEMENT          *
 ******************************************/


exports.setUp = function(client) {

  var mod = {};

  mod.addUserToProject = function(id, pid, fn) {
    //Add user as a contact to all project members
    client.smembers('projects:' + pid + ':users', function(err, array) {
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
        pid = val;
        client.set('projects:' + pid + ':name', name);
        client.set('projects:' + pid + ':users', cids);
        //TODO send notification to all users except creator
      }
      return process.nextTick(function () {
        fn(err, null);
      });
    });
  };

  mod.deleteProject = function(id, pid, fn) {
    client.srem('projects:' + pid + ':users', id);
    client.scard('projects:' + pid + ':users', function(err, val) {
      if(!err && !val) {
        return client.del('projects:' + pid, fn(err, value));
      }
      //TODO send notification to all contacts except id
      return process.nextTick(function() {
        fn(err, val);
      });
    });
  };

  mod.addUserToProject = function(id, pid, fn) {
    var me = this;
    //Check if user exists
    return client.exists('users:' + id, function(err, val) {
      if(!err && val) {
        return me.addUserToProject(id, pid, function(err) {
          return me.addUserToProject(id, pid, function() {
            return client.sadd('projects:' + pid + ':users', id, fn);
          });
        });
        //TODO send notification to all contacts except id
      }
      return process.nextTick(function() {
        fn(err);
      });
    });
  };

  mod.inviteUserToProject = function(id, pid, providerId, provider, fn) {};

  mod.inviteEmailUserToProject = function(id, pid, email, fn) {};

  mod.inviteLinkUserToProject = function(id, pid, fn) {};

  return mod;

};
