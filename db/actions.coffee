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
    negativeActionsBufferSize = -cfg.ACTIONS_BUFFER_SIZE
    client.lrange "projects:#{pid}:#{type}", negativeActionsBufferSize, -1, (err, array) ->
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
      if not err and array and array.length
        actions = []
        return tools.asyncParallel array, (aid) ->
          client.hgetall "actions:#{aid}", (err, action) ->
            if err
              return tools.asyncOpt fn, err, []
            actions.push action
            return tools.asyncDone array, ->
              return tools.asyncOpt fn, null, actions

  mod.getElements = (cid, type, fn) ->
    client.lrange "canvases:#{cid}:#{type}", 0, -1, (err, actions) ->
      return tools.asyncOpt fn, null, [] if not actions or not actions.length

      if not err
        fetchedActions = []

        return tools.asyncParallel actions, (aid) ->
          client.hgetall "actions:#{aid}", (err, action) ->
            fetchedAction = JSON.parse(action.data)
            return tools.asyncOpt fn, err, [] if err

            if type is 'comment'
              return db.actions.getCommentTexts fetchedAction.elementId, (err, texts, elementIds) ->
                rarray = []
                for text, index in texts
                  rarray.push
                    text: text
                    elementId: elementIds[index]

                console.log rarray

                fetchedAction.texts = rarray
                fetchedActions.push fetchedAction
                tools.asyncDone actions, ->
                  tools.asyncOpt fn, null, fetchedActions
            else
              fetchedActions.push fetchedAction
              tools.asyncDone actions, ->
                tools.asyncOpt fn, null, fetchedActions

      return tools.asyncOpt fn, err, []

  mod.getCommentTexts = (eid, fn) ->
    client.lrange "comments:#{eid}:texts", 0, -1, (err, elementIds) ->
      if not err and elementIds and elementIds.length
        comments = []
        return client.mget elementIds.map(tools.commentText), (err, texts) -> fn(err, texts, elementIds)
      return tools.asyncOpt fn, err, []

  mod.updateComment = (data, fn) ->
    client.set "texts:#{data.elementId}", data.text
    client.rpush "comments:#{data.commentId}:texts", data.elementId
    return tools.asyncOpt fn, null, data

  return mod
