tools = require '../tools'

exports.configure = (app) ->
  tools.include __dirname, (mod, name) ->
    mod.configure app
