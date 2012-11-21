_ = require 'underscore'

tools = require '../tools'

exports.setUp = (client, db) ->

  mod = {}

  mod.add = (pid, fid, time, fn) ->
    client.incr 'canvases:next', (err, val) ->
      if not err
        canvas = {
          id: val
          project: pid
        }
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
        return tools.asyncParallel array, (left, cid) ->
          db.canvases.get cid, (err, canvas) ->
            if not err and canvas
              db.files.file canvas.file, (err, file) ->
                db.actions.getElements cid, (err, elements) ->
                  if not err
                    canvases.push {
                      canvasId: cid
                      file: file
                      elements: elements
                    }
                  return tools.asyncDone left, ->
                    return tools.asyncOpt fn, null, canvases
      return tools.asyncOpt fn, err, []

  mod.setProperties = (cid, properties, fn) ->
    client.hmset "canvases:#{cid}", properties, fn

  return mod
