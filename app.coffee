
http = require 'http'

expressUp = require './setup/express'
tools = require './tools'
cfg = require './config'

app = expressUp.setUp()

server = http.createServer app

process.on 'uncaughtException', (err) ->
  console.log err

tools.startCluster tools.exitNotify, (cluster) ->
  console.log "Worker #{cluster.worker.id} started: #{cluster.worker.process.pid}"
  server.listen cfg.PORT, cfg.HOST, expressUp.start
