redis = require 'redis'
_ = require 'lodash'

tools = require '../tools'

client = redis.createClient()

client.on "error", (err) ->
  console.log "Error #{err}"

defaults =
  tools: require '../tools'
  cfg: require '../config'
  smtp: require '../smtp'

tools.include __dirname, (mod, name) ->
  obj = mod.setUp client, module
  module[name] = obj
, defaults

module.exports = module
