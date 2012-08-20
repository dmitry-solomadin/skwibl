
/**
 * Module dependencies.
 */

var cluster = require('cluster')
  , os = require('os')
  , http = require('http');

var express_config = require('./express_config');

var app = express_config.setUp();

var numCPUs = os.cpus().length;

var server = http.createServer(app);


/*
 * Server start
 */
if(cluster.isMaster) {
  for(var i = 0; i < numCPUs; i++) {
    cluster.fork();
  }
  cluster.on('exit', function(worker, code, signal) {
    console.log('Worker ' + worker.id + ' died: ' + worker.process.pid);
  });
} else {
  console.log('Worker ' + cluster.worker.id + ' started: ' + cluster.worker.process.pid);
  server.listen(app.get('port'), app.get('host'), express_config.start(app));
}
