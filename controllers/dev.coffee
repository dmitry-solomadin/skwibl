
db = require '../db'
tools = require '../tools'
cfg = require '../config'

exports.player = (req, res) ->
  return res.render 'dev/index',
    template: 'player'
    user: req.user

exports.conns = (req, res, next) ->
  user = req.user
  name = tools.getName user
  db.auth.connections user.id, (err, connections) ->
    unless err
      conns =
        facebook: off
        google: off
        linkedin: off
        dropbox: off
        yahoo: off
      if connections
        for el in connections
          conns[el] = on
      return res.render 'dev/index',
        template: 'profile'
        user: user
        id: user.id
        name: name
        connections: conns
    return next err

exports.integration = (req, res) ->
  service = req.body.service
  return res.send true
