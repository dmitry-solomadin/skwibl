tools = require '../tools'

exports.setUp = (client, db) ->
  mod = {}

  mod.add = (pid, fid, time, fn) ->
    client.incr 'canvases:next', (err, val) ->
      if not err
        canvas =
          id: val
          project: pid
        canvas.file = fid if fid
        canvas.time = time if time
        client.hmset "canvases:#{val}", canvas
        client.sadd "projects:#{pid}:canvases", val
        return tools.asyncOpt fn, null, canvas
      return tools.asyncOpt fn, err, null

  mod.get = (cid, fn) ->
    client.hgetall 'canvases:' + cid, fn

  mod.index = (pid, fn) ->
    client.smembers "projects:#{pid}:canvases", (err, array) ->
      if not err and array and array.length
        canvases = []
        return tools.asyncParallel array, (cid) ->
          db.canvases.get cid, (err, canvas) ->
            if not err and canvas
              db.files.findById canvas.file, (err, file) ->
                db.actions.getElements cid, "element", (err, elements) ->
                  db.actions.getElements cid, "comment", (err, comments) ->
                    unless err
                      canvases.push
                        canvasId: cid
                        file: file
                        elements: elements
                        comments: comments
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
