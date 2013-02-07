#
# POST
# Add new empty canvas
#
exports.addEmpty = (req, res) =>
  return @db.canvases.add req.body.pid, null, null, (err, canvas) =>
    #TODO send event to socket server
    return res.json error: err if err
    return res.json canvas

#
# POST
# Add new empty canvas
#
exports.initFirst = (req, res) =>
  return @db.canvases.initFirst req.body.pid, (err, canvasId) =>
    #TODO send event to socket server
    return res.json error: err if err
    return res.send canvasId