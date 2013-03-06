_ = require 'lodash'

tools = require '../tools'
GoogleAnalytics = require 'ga'

module

defaults =
  db: require '../db'
  tools: require '../tools'
  cfg: require '../config'
  ga: new GoogleAnalytics("skwibl.com", "UA-37020806-1")

tools.include __dirname, (mod, name) ->
  module[name] = mod
, defaults

module.exports = module
