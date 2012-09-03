/******************************************
 *          MIDDLEWARE FUNCTIONS          *
 ******************************************/


exports.setUp = function(client) {

  var mod = {};

  mod.isUserProjectMember = function(id, pid, fn) {
    client.sismember('projects:' + pid + ':users', fn);
  };

  mod.isUserProjectOwner = function(id, pid, fn) {
    client.hget('projects:' + pid, 'owner', function(err, val) {
      if(!err && val === id) {
        return process.nextTick(function() {
          fn(null, true);
        });
      }
      return process.nextTick(function() {
        fn(err, false);
      });
    })
  };

  mod.isUserInvited = function(id, pid, fn) {
    client.sismember('projects:' + pid + ':unconfirmed', id, fn);
  };

  return mod;

};
