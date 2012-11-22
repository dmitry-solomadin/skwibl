
tools = require '../tools'
cfg = require '../config'

exports.setUp = (client, db) ->

  mod = {}

  mod.update = (project, owner, type, data, fn) ->
    aid = data.element.elementId
    action = {}
    action.project = project
    action.owner = owner
    action.type = type
    action.canvas = canvasId if data.element.canvasId
    actions.comment = true if data.comment
    action.time = new Date
    action.data = data.element
    client.hmset "actions:#{aid}", action
    client.rpush "projects:#{project}:#{type}", val
    return tools.asyncOpt fn, null, action

  mod.delete = (aid, fn) ->
    client.del "actions:#{aid}", fn

  mod.get = (project, type, fn) ->
    client.lrange "projects:#{project}:#{type}", -cfg.ACTIONS_BUFFER_SIZE, -1, (err, array) ->
      if not err and array and array.length
        actions = []
        return tools.asyncParallel array, (left, aid) ->
          client.hgetall "actions:#{aid}", (err, action) ->
            if err
              return tools.asyncOpt fn, err, []
            actions.push action
            return tools.asyncDone left, ->
              return tools.asyncOpt fn, null, actions

  mod.getCanvas = (cid, type, fn) ->
    client.lrange "projects:#{cid}:#{type}", 0, -1, (err, array) ->
      if not err and  array and array.length
        actions = []
        return tools.asyncParallel array, (left, aid) ->
          client.hgetall "actions:#{aid}", (err, action) ->
            if err
              return tools.asyncOpt fn, err, []
            actions.push action
            return tools.asyncDone left, ->
              return tools.asyncOpt fn, null, actions

  mod.getElements = (cid, fn) ->
    client.lrange "projects:#{cid}:elements", 0, -1, (err, array) ->
      if not err and array and array.length
        actions = []
        return tools.asyncParallel array, (left, aid) ->
          client.hgetall "actions:#{aid}", (err, action) ->
            if err
              return tools.asyncOpt fn, err, []
            if action.comment
              #TODO get comment texts
              console.log 'TODO'
            actions.push action
            return tools.asyncDone left, ->
              return tools.asyncOpt fn, null, actions

  mod.getComments = (eid, fn) ->
    client.lrange "comments:#{eid}:texts", 0, -1, (err, array) ->
      if not err and array and array.length
        comments = []
        return client.mget array.map(tools.commentText), fn

  mod.updateComment = (data, fn) ->
    client.set "texts:#{data.elementId}", data.text
    client.rpush "comments:#{data.commentId}:texts", data.elementId
    return tools.asyncOpt fn, null, data

  return mod
