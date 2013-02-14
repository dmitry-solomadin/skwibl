exports.add = (owner, cid, pid, name, mime, posX, posY, fn) =>
  return @client.incr 'files:next', (err, fid) =>
    return @tools.asyncOpt(fn, err, null) if err
    file =
      id: fid
      name: name
      mime: mime
      owner: owner
      posX: posX
      posY: posY
    if cid
      @client.hmset "files:#{fid}", file, @tools.logError
      @db.canvases.setProperties cid,
        initialized: true
        file: fid
      @client.sadd "projects:#{pid}:files", fid
      @db.activities.addForAllInProject pid, 'fileUpload', owner, [owner], {canvasId: cid, fileId: fid}
      return @tools.asyncOpt fn, null, canvasId: cid, element: file
    @client.hmset "files:#{fid}", file, @tools.logError
    @client.sadd "projects:#{pid}:files", fid
    time = 0 if @tools.getFileType(mime) is 'video'
    @db.canvases.add pid, file, time, (err, canvas) =>
      @db.activities.addForAllInProject pid, 'fileUpload', owner, [owner], {canvasId: canvas.id, fileId: fid}
      return @tools.asyncOpt fn, err, null if err
      return @tools.asyncOpt fn, err, canvasId: canvas.id, element: file, canvasName: canvas.name

exports.get = (uid, fn) =>
  #TODO

exports.project = (pid, fn) =>
  #TODO

exports.findById = (fid, fn) =>
  @client.hgetall "files:#{fid}", (err, file) =>
    if not err
      return @tools.asyncOpt fn, null, file
    return @tools.asyncOpt fn, err

exports.delete = (id, fn) =>
  #TODO

exports.setProperties = (id, properties, fn) =>
  #TODO
