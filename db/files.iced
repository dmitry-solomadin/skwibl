
tools = require '../tools'

exports.setUp = (client, db) ->

  mod = {}

  mod.add = (owner, cid, pid, name, mime, fn) ->
    return client.incr 'files:next', (err, fid) ->
      return tools.asyncOpt(fn, err, null) if err
      file =
        id: fid
        name: name
        mime: mime
        owner: owner
      if cid
        client.hmset "files:#{fid}", file
        db.canvases.setProperties cid,
          initialized: true
          file: fid
        client.sadd "projects:#{pid}:files", fid
        return tools.asyncOpt fn, null, canvasId: cid, element: file
      client.hmset "files:#{fid}", file
      client.sadd "projects:#{pid}:files", fid
      time = 0 if tools.getFileType(mime) is 'video'
      db.canvases.add pid, file, time, (err, canvas) ->
        return tools.asyncOpt fn, err, null if err
        return tools.asyncOpt fn, null, canvasId: canvas.id, element: file, canvasName: canvas.name

  mod.get = (uid, fn) ->
    #TODO

  mod.project = (pid, fn) ->
    #TODO

  mod.findById = (fid, fn) ->
    client.hgetall "files:#{fid}", (err, file) ->
      if not err
        return tools.asyncOpt fn, null, file
      return tools.asyncOpt fn, err

  mod.delete = (id, fn) ->
    #TODO

  mod.setProperties = (id, properties, fn) ->
    #TODO

  return mod
