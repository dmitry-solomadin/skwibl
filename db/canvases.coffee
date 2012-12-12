tools = require '../tools'

exports.setUp = (client, db) ->
  mod = {}

  mod.add = (pid, fid, time, fn) ->
    client.incr 'canvases:next', (err, cid) ->
      if not err
        canvas =
          id: cid
          project: pid
        canvas.file = fid if fid
        canvas.time = time if time
        canvas.createdAt = new Date().getTime()
        client.hmset "canvases:#{cid}", canvas
        client.sadd "projects:#{pid}:canvases", cid
        return tools.asyncOpt fn, null, canvas
      return tools.asyncOpt fn, err, null

  mod.get = (cid, fn) ->
    client.hgetall 'canvases:' + cid, fn

  mod.index = (pid, fn) ->
    client.sort "projects:#{pid}:canvases", "by", "canvases:*->createdAt", (err, array) ->
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
        client.smembers "projects:#{canvas.project}:canvases", (err, canvases) ->
          if not err and canvases and canvases.length
            if canvases.length <= 1
              db.canvases.clear cid
              client.hdel "canvases:#{cid}", "file"
              tools.asyncOpt fn, null, null
            else
              client.srem "projects:#{canvas.project}:canvases", cid
              db.canvases.clear cid
              client.del "canvases:#{cid}", cid
      tools.asyncOpt fn, null, null

  mod.deleteActions = (cid, type, fn) ->
    client.lrange "canvases:#{cid}:#{type}", 0, -1, (err, actionIds) ->
      return tools.asyncOpt fn, null, null if not actionIds or not actionIds.length

      return tools.asyncParallel actionIds, (aid) ->
        db.actions.delete aid, fn

        return tools.asyncDone actionIds, ->
          return tools.asyncOpt fn, null, null

  mod.setProperties = (cid, properties) ->
    client.hmset "canvases:#{cid}", properties

  return mod
