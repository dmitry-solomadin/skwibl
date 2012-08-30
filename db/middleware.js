/******************************************
 *          MIDDLEWARE FUNCTIONS          *
 ******************************************/


exports.setUp = function(client) {

  var mod = {};

  mod.isUserProjectMember = function(id, pid, fn) {
    client.sismember('projects:' + pid + ':users', fn);
  };

  return mod;

};
