/******************************************
 *          MIDDLEWARE FUNCTIONS          *
 ******************************************/


exports.setUp = function(client) {

  var mod = {};

  mod.isUserProjectMember = function(id, rid, fn) {
    client.sismember('projects:' + rid + ':users', fn);
  };

  return mod;

};
