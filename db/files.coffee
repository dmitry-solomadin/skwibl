
_ = require 'underscore'

tools = require '../tools'

exports.setUp = (client, db) ->

  mod = {}

  mod.add = (owner, cid, pid, name, mime, fn) ->
    return client.incr 'files:next', (err, val) ->
      if not err
        if cid
          file =
            elementId: val
            name: name
            mime: mime
            owner: owner

          client.hmset "files:#{val}", file
          db.canvases.setProperties "canvases:#{cid}", {
            file: val
          }
          client.sadd "projects:#{pid}:files", val
          return tools.asyncOpt fn, null, {
            canvasId: cid
            element: file
          }

        client.incr 'canvases:next', (err, cid) ->
          if not err
            file = {
              elementId: val
              name: name
              mime: mime
              owner: owner
            }
            client.hmset "files:#{val}", file
            client.sadd "projects:#{pid}:files", val

            time = 0 if tools.getFileType(mime) is 'video'

            db.canvases.add pid, val, time
            return tools.asyncOpt fn, null, {
              canvasId: cid
              element: file
            }
          return tools.asyncOpt fn, err, null
      return tools.asyncOpt fn, err, null

  mod.get = (uid, fn) ->
    #TODO

  mod.project = (pid, fn) ->
    #TODO

  mod.file = (fid, fn) ->
    client.hgetall "files:#{fid}", (err, file) ->
      if not err
        return tools.asyncOpt fn, null, file
      return tools.asyncOpt fn, err

  mod.delete = (id, fn) ->
    #TODO

  mod.findById = (id, fn) ->
    #TODO

  mod.setProperties = (id, properties, fn) ->
    #TODO

  return mod
