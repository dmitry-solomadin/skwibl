
tools = require '../tools'

exports.setUp = (client, db) ->

  mod = {}

  mod.add = (owner, cid, pid, name, mime, fn) ->
    return client.incr 'files:next', (err, val) ->
      return tools.asyncOpt(fn, err, null) if err

      file =
        id: val
        name: name
        mime: mime
        owner: owner

      if cid
        client.hmset "files:#{val}", file
        db.canvases.setProperties cid, file: val
        client.sadd "projects:#{pid}:files", val
        return tools.asyncOpt fn, null, canvasId: cid, element: file

      client.hmset "files:#{val}", file
      client.sadd "projects:#{pid}:files", val

      time = 0 if tools.getFileType(mime) is 'video'

      db.canvases.add pid, val, time, (err, canvas) ->
        return tools.asyncOpt fn, err, null if err
        return tools.asyncOpt fn, null, canvasId: canvas.id, element: file

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
