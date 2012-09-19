
/**
 * Module dependencies.
 */

var http = require('http');

var express_config = require('./express_config')
  , tools = require('./tools');

var app = express_config.setUp();

var server = http.createServer(app);

tools.startCluster(tools.exitNotify, function(cluster) {
  console.log('Worker ' + cluster.worker.id +
  ' started: ' + cluster.worker.process.pid);
  server.listen(app.get('port'), app.get('host'), express_config.start(app));
});
