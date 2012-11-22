fs = require 'fs'
path = require 'path'
formidable = require 'formidable'

db = require '../db'
tools = require '../tools'
cfg = require '../config'

#
# GET
# User files
#
exports.get = (req, res) ->
  res.render 'partials/files'

#
# GET
# Project files
#
exports.project = (req, res) ->
  #TODO
  console.log 'TODO'

#
# GET
# The file from the project
#
exports.file = (req, res) ->
  fid = req.params.fid
  db.files.file fid, (err, file) ->
    return res.send err if err
    type = tools.getFileType file.mime
    res.writeHead 200, 'Content-Type': file.mime

    rs = fs.createReadStream "./uploads/#{file.project}/#{type}/#{file.name}"
    rs.pipe res

#
# POST
# Add file from cloud source
#
exports.add = (req, res) ->
  #TODO
  console.log 'TODO'

#
# POST
# delete file
#
exports.delete = (req, res) ->
  #TODO
  console.log 'TODO'

#
# POST
# Update file
#
exports.update = (req, res) ->
  #TODO
  console.log 'TODO'

#
# POST
# Upload file
#
exports.upload = (req, res, next) ->
  #TODO implement upload continue
  if req.xhr
    pid = req.query.pid
    dir = "./uploads/#{pid}"
    size = req.header 'x-file-size'
    name = path.basename req.header 'x-file-name'
    mime = tools.getFileMime path.extname name
    type = tools.getFileType mime
    unless mime
      return res.json
        success: false
        name: name
        error: 'Unsupported file type'
    ws = fs.createWriteStream "#{dir}/#{type}/#{name}",
      mode: cfg.FILE_PERMISSION
      flags: 'w'
    console.log 'upload'
    ws.on 'error', (err) ->
      console.log err
    ws.on 'drain', ->
      console.log 'drain'
      req.resume()
    ws.on 'close', ->
      console.log 'close'
    req.on 'data', (chunk) ->
      console.log 'chunk'
      ws.write chunk
    req.on 'end', ->
      ws.destroySoon()
      console.log 'end'
      return db.files.add req.user.id, pid, name, mime, (err, data) ->
        console.log 'here'
        return res.json
          success: yes
          canvasId: data.canvasId
          element: data.element
    req.on 'close', ->
      ws.destroy()
      return res.json
        success: no
        name: name
  else
    form = new formidable.IncomingForm()
    form.uploadDir = "#{dir}/#{type}/"
    form.keepExtensions = yes
    form.parse req, (err, fields, files) ->
      return db.files.add req.user.id, pid, name, mime, (err, file) ->
        return res.json
          success: true
          id: file.id
          name: name
