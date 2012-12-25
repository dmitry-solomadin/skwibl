tools = require '../tools'

exports.configure = (app, passport) ->
  tools.include __dirname, (mod, name) ->
    mod.configure app, passport
