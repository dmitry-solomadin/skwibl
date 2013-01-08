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
  # We actually send two post request from the client but the method supports also sending multiple files in on form request
exports.upload = (req, res, next) ->
  fileCount = 0
  files = []
  end = ->
    fileCount--
    if fileCount is 0
      savedFiles = []
      tools.asyncParallel files, (file) ->
        db.files.add req.user.id, req.cid, req.pid, file.name, file.mime, (err, savedFile) ->
          savedFiles.push savedFile
          return tools.asyncDone files, ->
            return res.json savedFiles
  form = new formidable.IncomingForm()
  form.uploadDir = cfg.UPLOADS_TMP
  form.on 'field', (name, value)->
    req[name] = value
  form.on 'fileBegin', ->
    console.log "fileBegin"
  form.on 'file', (name, file) ->
    fileCount++
    files.push file
    pid = req.pid
    cid = req.cid
    size = file.length
    # todo cfg.minFileSize and cfg.maxFileSize are not yet defined.
    if cfg.minFileSize and cfg.minFileSize > size
      fs.unlink file.path
      return
    if cfg.maxFileSize and size > cfg.maxFileSize
      fs.unlink file.path
      return
    mime = file.mime
    type = tools.getFileType mime
    unless tools.isMimeSupported mime
      fs.unlink file.path
      return
    uploadDir = "#{cfg.UPLOADS}/#{pid}/#{type}"
    fs.rename file.path, "#{uploadDir}/#{file.name}", (err) ->
      console.log "unexpected error. implement manual copy process" if err
      return end()
  form.on 'aborted', ->
    console.log "abort"
  form.on 'error', (err) ->
    console.log "error: ", err
  form.on 'end', ->
    console.log "end"
  form.parse req

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
      return request url: url, oauth: oauth, json: true, (err, response, body) ->
        console.log response.statusCode, body, typeof body
        return res.send body
    return res.send no