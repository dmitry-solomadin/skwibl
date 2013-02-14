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
  client: client
  db: module

tools.include __dirname, (mod, name) ->
  module[name] = mod
, defaults

module.exports = module
