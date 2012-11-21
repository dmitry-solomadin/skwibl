
http = require 'http'

expressUp = require './setup/express'
tools = require './tools'

app = expressUp.setUp()

server = http.createServer app

tools.startCluster tools.exitNotify, (cluster) ->
  console.log "Worker #{cluster.worker.id} started: #{cluster.worker.process.pid}"
  server.listen app.get('port'), app.get('host'), expressUp.start(app)
