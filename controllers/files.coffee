request = require 'request'
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
  db.files.findById fid, (err, file) ->
    return res.send err if err
    type = tools.getFileType file.mime
    res.writeHead 200, 'Content-Type': file.mime

    rs = fs.createReadStream "./uploads/#{req.params.pid}/#{type}/#{file.name}"
    rs.pipe res

#
# POST
# Add file from cloud source
#
exports.add = (req, res) ->

#
# POST
# delete file
#
exports.delete = (req, res) ->

#
# POST
# Update file
#
exports.update = (req, res) ->

#
# POST
# Upload file
#
exports.upload = (req, res, next) ->
  #TODO implement upload continue
  if req.xhr
    pid = req.query.pid
    cid = req.query.cid
    dir = "./uploads/#{pid}"
    size = req.header 'x-file-size'
    name = decodeURIComponent path.basename(req.header('x-file-name'))
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
      return db.files.add req.user.id, cid, pid, name, mime, (err, data) ->
        return res.json
          success: yes
          canvasId: data.canvasId
          name: data.canvasName
          fileId: data.element.id

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
      return db.files.add req.user.id, cid, pid, name, mime, (err, file) ->
        return res.json
          success: true
          id: file.id
          name: name

#
# GET
# Dropbox files
#
exports.dropbox = (req, res) ->
  db.auth.getConnection req.user.id, 'dropbox', (err, connection) ->
    if not err and connection
      oauth =
        consumer_key: cfg.DROPBOX_APP_KEY
        consumer_secret: cfg.DROPBOX_APP_SECRET
        token: connection.oauth_token
        token_secret: connection.oauth_token_secret
      console.log oauth
      path = req.query.path or ''
      console.log path
      url = "https://api.dropbox.com/1/metadata/dropbox/#{path}"
      return request url: url, oauth: oauth, (err, response, body) ->
        console.log response.statusCode, body
        return res.send body
    return res.send no