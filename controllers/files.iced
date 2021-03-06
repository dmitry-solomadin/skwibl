request = require 'request'
fs = require 'fs'
path = require 'path'
formidable = require 'formidable'

#
# GET
# User files
#
exports.get = (req, res) =>
  res.render 'partials/files'

#
# GET
# Project files
#
exports.project = (req, res) =>
  #TODO
  console.log 'TODO'

#
# GET
# The file from the project
#
exports.file = (req, res) =>
  fid = req.params.fid
  size = req.query.size
  size = if size then "#{size}/" else ''
  @db.files.findById fid, (err, file) =>
    return res.send err if err
    type = @tools.getFileType file.mime
    name = "./uploads/#{req.params.pid}/#{type}/#{size}#{file.name}"
    fs.exists name, (exists) =>
      return res.send '' unless exists
      res.writeHead 200, 'Content-Type': file.mime
      rs = fs.createReadStream name
      rs.pipe res

#
# POST
# Add file from cloud source
#
exports.add = (req, res) =>

  #
  # POST
  # delete file
  #
exports.delete = (req, res) =>

  #
  # POST
  # Update file
  #
exports.update = (req, res) =>

  #
  # POST
  # Upload file
  #
  # We actually send multiple post requests from the client but the method supports
  # sending multiple files in one post request
exports.upload = (req, res, next) =>
  fileCount = 0
  files = []
  end = =>
    fileCount--
    if fileCount is 0
      savedFiles = []
      data = req.body
      @tools.asyncParallel files, (file) =>
        @db.files.add req.user.id, data.cid, data.pid, file.name, file.type, data.posX, data.posY, (err, savedFile) =>
          element = savedFile.element
          @tools.makeProjectThumbs data.pid, element
          savedFiles.push savedFile
          return @tools.asyncDone files, =>
            return res.json savedFiles
  form = new formidable.IncomingForm()
  form.uploadDir = @cfg.UPLOADS_TMP
  form.on 'field', (name, value)=>
    req.body[name] = value
#   form.on 'fileBegin', =>
#     console.log "fileBegin"
  form.on 'file', (name, file) =>
    pid = req.body.pid
    cid = req.body.cid
    @db.mid.isMember req.user.id, pid, (err, val) =>
      return res.json new Error 'Access denied' unless val
      fileCount++
      files.push file
      size = file.length
      #TODO @cfg.MIN_FILE_SIZE and @cfg.MAX_FILE_SIZE are not yet defined.
      if @cfg.MIN_FILE_SIZE and @cfg.MIN_FILE_SIZE > size
        fs.unlink file.path
        return
      if @cfg.MAX_FILE_SIZE and size > @cfg.MAX_FILE_SIZE
        fs.unlink file.path
        return
      mime = file.type
      type = @tools.getFileType mime
      unless @tools.isMimeSupported mime
        fs.unlink file.path
        return
      uploadDir = "#{@cfg.UPLOADS}/#{pid}/#{type}"
      fs.rename file.path, "#{uploadDir}/#{file.name}", (err) =>
        console.log "unexpected error. implement manual copy process" if err
        return end()
#   form.on 'aborted', =>
#     console.log "abort"
#   form.on 'error', (err) =>
#     console.log "error: ", err
#   form.on 'end', =>
#     console.log "end"
  form.parse req

exports.uploadDropbox = (req, res) =>
  fileCount = req.body.linkInfos.length
  pid = req.body.pid
  posX = req.body.posX
  posY = req.body.posY

  end = =>
    fileCount--
    if fileCount is 0
      savedFiles = []
      @tools.asyncParallel req.body.linkInfos, (linkInfo) =>
        @db.files.add req.user.id, linkInfo.cid, pid, linkInfo.name, linkInfo.mime, posX, posY, (err, savedFile) =>
          element = savedFile.element
          @tools.makeProjectThumbs pid, element
          savedFiles.push savedFile
          return @tools.asyncDone req.body.linkInfos, =>
            return res.json savedFiles

  for linkInfo in req.body.linkInfos
    linkInfo.name = path.basename linkInfo.link
    linkInfo.mime = @tools.getFileMime path.extname linkInfo.name
    linkInfo.type = @tools.getFileType linkInfo.mime

    uploadDir = "./uploads/#{pid}/#{linkInfo.type}"
    filePath = "#{uploadDir}/#{linkInfo.name}"
    r = request(linkInfo.link + "?dl=1")
    r.on "end", => end()
    r.pipe fs.createWriteStream(filePath)

#
# GET
# Dropbox files
#TODO this method WIP it should connect dropbox from the server side
exports.dropbox = (req, res) =>
  @db.auth.getConnection req.user.id, 'dropbox', (err, connection) =>
    if not err and connection
      oauth =
        consumer_key: @cfg.DROPBOX_APP_KEY
        consumer_secret: @cfg.DROPBOX_APP_SECRET
        token: connection.oauth_token
        token_secret: connection.oauth_token_secret
      console.log oauth
      path = req.query.path or ''
      console.log path
      url = "https://api.dropbox.com/1/metadata/dropbox/#{path}"
      return request url: url, oauth: oauth, json: true, (err, response, body) =>
        console.log response.statusCode, body, typeof body
        return res.send body
    return res.send no
