_ = require 'lodash'

tools = require '../tools'

defaults = ctrls: require '../controllers'

exports.configure = (app) ->
  tools.include __dirname, (mod, name) ->
    _.extend mod, defaults
    mod.configure app
