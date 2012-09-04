/******************************************
 *          MIDDLEWARE FUNCTIONS          *
 ******************************************/


exports.setUp = function(client, db) {

  var mod = {};

  mod.isMember = function(id, pid, fn) {
    client.sismember('projects:' + pid + ':users', fn);
  };

  mod.isOwner = function(id, pid, fn) {
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

  mod.isInvited = function(id, pid, fn) {
    client.sismember('projects:' + pid + ':unconfirmed', id, fn);
  };

  return mod;

};
