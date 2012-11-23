
tools = require '../tools'

exports.configure = (sio) ->
  tools.include __dirname, (mod, name) ->
    mod.configure sio
