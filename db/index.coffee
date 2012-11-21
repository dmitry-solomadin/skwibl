redis = require 'redis'

tools = require '../tools'

module
client = redis.createClient()

client.on "error", (err) ->
  console.log "Error #{err}"

tools.include __dirname, (mod, name) ->
  obj = mod.setUp client, module
  module[name] = obj

module.exports = module
