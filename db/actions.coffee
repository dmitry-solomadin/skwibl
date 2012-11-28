
tools = require '../tools'
cfg = require '../config'

exports.setUp = (client, db) ->

  mod = {}

  mod.update = (pid, owner, type, data, fn) ->
    aid = data.element.elementId
    action = {}
    action.project = pid
    action.owner = owner
    action.type = type
    action.canvasId = data.canvasId if data.canvasId
    actions.comment = true if data.comment
    action.time = new Date
    action.data = JSON.stringify(data.element)

    client.exists "actions:#{aid}", (err, val) ->
      client.hmset "actions:#{aid}", action
      if not err and not val
        client.rpush "projects:#{pid}:#{type}", aid
        client.rpush "canvases:#{data.canvasId}:#{type}", aid if data.canvasId

      tools.asyncOpt fn, null, action

  mod.delete = (aid, fn) ->
    client.del "actions:#{aid}", fn

  mod.get = (pid, type, fn) ->
    client.lrange "projects:#{pid}:#{type}", -cfg.ACTIONS_BUFFER_SIZE, -1, (err, array) ->
      if not err and array and array.length
        actions = []
        return tools.asyncParallel array, (aid) ->
          client.hgetall "actions:#{aid}", (err, action) ->
            if err
              return tools.asyncOpt fn, err, []
            actions.push action
            return tools.asyncDone array, ->
              return tools.asyncOpt fn, null, actions

  mod.getCanvas = (pid, type, fn) ->
    client.lrange "projects:#{pid}:#{type}", 0, -1, (err, array) ->
      if not err and  array and array.length
        actions = []
        return tools.asyncParallel array, (aid) ->
          client.hgetall "actions:#{aid}", (err, action) ->
            if err
              return tools.asyncOpt fn, err, []
            actions.push action
            return tools.asyncDone array, ->
              return tools.asyncOpt fn, null, actions

  mod.getElements = (cid, fn) ->
    client.lrange "canvases:#{cid}:element", 0, -1, (err, actions) ->
      return tools.asyncOpt fn, null, [] if not actions or not actions.length

      if not err
        fetchedActions = []
        return tools.asyncParallel actions, (aid) ->
          return client.hgetall "actions:#{aid}", (err, action) ->
            if err
              return tools.asyncOpt fn, err, []
            if action.comment
              #TODO get comment texts
              console.log 'TODO'
            fetchedActions.push action.data
            return tools.asyncDone actions, ->
              return tools.asyncOpt fn, null, fetchedActions

      return tools.asyncOpt fn, err, []

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
