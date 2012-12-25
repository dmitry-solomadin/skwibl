
http = require 'http'

socketUp = require './setup/socket'
winstonUp = require './setup/winston'
tools = require './tools'
cfg = require './config'

logger = winstonUp.setUp('socket.io')

server = http.createServer()

# process.on 'uncaughtException', (err) ->
#   console.error err.stack

tools.startCluster tools.exitNotify, (cluster) ->
  logger.info "Worker #{cluster.worker.id} started: #{cluster.worker.process.pid}"
  socketUp.setUp server, logger
  server.listen cfg.SOCKET_PORT, cfg.HOST, socketUp.start(logger)
