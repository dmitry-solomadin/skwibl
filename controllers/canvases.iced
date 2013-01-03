db = require '../db'

#
# POST
# Add new empty canvas
#
exports.addEmpty = (req, res) ->
  return db.canvases.add req.body.pid, null, null, (err, canvas) ->
    return res.json canvas

#
# POST
# Add new empty canvas
#
exports.initFirst = (req, res) ->
  return db.canvases.initFirst req.body.pid, (err) ->
    return res.json err?