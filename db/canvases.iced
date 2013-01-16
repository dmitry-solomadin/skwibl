tools = require '../tools'

exports.setUp = (client, db) ->
  mod = {}

  mod.add = (pid, file, time, fn) ->
    return client.llen "projects:#{pid}:canvases", (err, count) ->
      return client.incr 'canvases:next', (err, cid) ->
        unless err
          canvas =
            id: cid
            createdAt: Date.now()
            project: pid
          canvas.time = time if time
          canvas.file = file.id if file
          canvas.initialized = true if count > 0
          if file and file.name.trim().length > 0
            canvas.name = file.name
          else
            canvas.name = "Canvas #{count + 1}"
          client.hmset "canvases:#{cid}", canvas
          client.lpush "projects:#{pid}:canvases", cid
          return tools.asyncOpt fn, null, canvas
        return tools.asyncOpt fn, err, null

  mod.initFirst = (pid, fn) ->
    return client.lrange "projects:#{pid}:canvases", 0, 0, (err, val) ->
      client.hset "canvases:#{val}", "initialized", "true"
      return tools.asyncOpt fn, err, null

  mod.get = (cid, fn) ->
    client.hgetall 'canvases:' + cid, fn

  mod.index = (pid, fn) ->
    client.lrange "projects:#{pid}:canvases", 0, -1, (err, array) ->
      if not err and array and array.length
        canvases = []
        return tools.asyncParallel array, (cid, index) ->
          db.canvases.get cid, (err, canvas) ->
            if not err and canvas
              db.files.findById canvas.file, (err, file) ->
                canvas.file = file
                db.actions.getElements cid, "element", (err, elements) ->
                  canvas.elements = elements
                  db.actions.getElements cid, "comment", (err, comments) ->
                    canvas.comments = comments
                    unless err
                      canvases[index] = canvas
                    return tools.asyncDone array, ->
                      return tools.asyncOpt fn, null, canvases
      return tools.asyncOpt fn, err, []

  mod.clear = (cid) ->
    db.canvases.deleteActions cid, "element"
    db.canvases.deleteActions cid, "comment"

  mod.delete = (cid, fn) ->
    db.canvases.get cid, (err, canvas)->
      if not err and canvas
        client.lrange "projects:#{canvas.project}:canvases", 0, -1, (err, canvases) ->
          if not err and canvases and canvases.length
            if canvases.length <= 1
              db.canvases.clear cid
              client.hdel "canvases:#{cid}", "file"
              client.hset "canvases:#{cid}", "initialized", "false"
              tools.asyncOpt fn, null, null
            else
              client.lrem "projects:#{canvas.project}:canvases", 0, cid
              db.canvases.clear cid
              client.del "canvases:#{cid}", cid
      tools.asyncOpt fn, null, null

  mod.deleteActions = (cid, type, fn) ->
    client.lrange "canvases:#{cid}:#{type}", 0, -1, (err, array) ->
      return tools.asyncOpt fn, null, null if not array or not array.length
      return tools.asyncParallel array, (aid) ->
        db.actions.delete aid, fn
        return tools.asyncDone array, ->
          return tools.asyncOpt fn, null, null

  mod.setProperties = (cid, properties) ->
    client.hmset "canvases:#{cid}", properties

  mod.commentNumber = (cid, fn) ->
    client.hget "canvases:#{cid}", 'nextComment', fn

  return mod
