
http = require 'http'

expressUp = require './setup/express'
winstonUp = require './setup/winston'
tools = require './tools'
cfg = require './config'

logger = winstonUp.setUp('express')

app = expressUp.setUp(logger)

server = http.createServer app

# process.on 'uncaughtException', (err) ->
#   console.error err.stack

tools.startCluster tools.exitNotify, (cluster) ->
  logger.info "Worker #{cluster.worker.id} started: #{cluster.worker.process.pid}"
  server.listen cfg.PORT, cfg.HOST, expressUp.start(logger)
