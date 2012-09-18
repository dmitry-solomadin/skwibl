
/**
 * Module dependencies.
 */

var http = require('http');

var socket_config = require('./socket_config')
  , tools = require('./tools')
  , cfg = require('./config');

var server = http.createServer();

tools.startCluster(tools.exitNotify, function(cluster) {
  console.log('Worker ' + cluster.worker.id +
  ' started: ' + cluster.worker.process.pid);
  socket_config.setUp(server);
  server.listen(cfg.SOCKET_PORT, cfg.HOST, socket_config.start);
});
