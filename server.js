
/**
 * Module dependencies.
 */

var http = require('http');

var socketUp = require('./setup/socket')
  , tools = require('./tools')
  , cfg = require('./config');

var server = http.createServer();

tools.startCluster(tools.exitNotify, function(cluster) {
  console.log('Worker ' + cluster.worker.id +
  ' started: ' + cluster.worker.process.pid);
  socketUp.setUp(server);
  server.listen(cfg.SOCKET_PORT, cfg.HOST, socketUp.start);
});
