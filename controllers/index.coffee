
tools = require '../tools'

module

tools.include __dirname, (mod, name) ->
  module[name] = mod

module.exports = module
