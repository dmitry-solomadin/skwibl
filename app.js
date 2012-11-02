
/**
 * Module dependencies.
 */

var http = require('http');

var expressUp = require('./setup/express')
  , tools = require('./tools');

var app = expressUp.setUp();

var server = http.createServer(app);

tools.startCluster(tools.exitNotify, function(cluster) {
  console.log('Worker ' + cluster.worker.id +
  ' started: ' + cluster.worker.process.pid);
  server.listen(app.get('port'), app.get('host'), expressUp.start(app));
});
