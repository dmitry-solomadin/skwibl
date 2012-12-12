
http = require 'http'

socketUp = require './setup/socket'
tools = require './tools'
cfg = require './config'

server = http.createServer()

process.on 'uncaughtException', (err) ->
  console.error err.stack

tools.startCluster tools.exitNotify, (cluster) ->
  console.log "Worker #{cluster.worker.id} started: #{cluster.worker.process.pid}"
  socketUp.setUp server
  server.listen cfg.SOCKET_PORT, cfg.HOST, socketUp.start
