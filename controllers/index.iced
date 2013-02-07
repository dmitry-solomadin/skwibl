_ = require 'lodash'

tools = require '../tools'

module

defaults =
  db: require '../db'
  tools: require '../tools'
  cfg: require '../config'

tools.include __dirname, (mod, name) ->
  _.extend mod, defaults
  module[name] = mod

module.exports = module
