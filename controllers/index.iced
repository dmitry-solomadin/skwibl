_ = require 'lodash'

tools = require '../tools'

module

defaults =
  db: require '../db'
  tools: require '../tools'
  cfg: require '../config'

tools.include __dirname, (mod, name) ->
  module[name] = mod
, defaults

module.exports = module
