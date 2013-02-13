childProcess = require 'child_process'

#
# POST
# Make screnshot by link
#
exports.linkScreenshot = (req, res) =>
  data = req.body
  bin = './bin/phantomjs'
  script = './scripts/rasterize.js'
  shortName = "#{data.link.split('/')[2] + Date.now()}.jpg"
  name = "./uploads/#{data.pid}/image/#{shortName}"
  args = [script, data.link, name, data.width, data.height]
  ph = childProcess.spawn bin, args
  ph.on 'exit', (code) =>
    unless code
      return @db.files.add req.user.id, null, data.pid, shortName, 'image', data.posX, data.posY, (err, file) =>
        element = file.element
        @tools.makeProjectThumbs data.pid, element
        return res.json error: err if err
        return res.json file
    return res.json error: new Error "Unable to get screenshot from the link #{data.link}"

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
