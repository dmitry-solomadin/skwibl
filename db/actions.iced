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

    return client.exists "actions:#{aid}", (err, val) ->
      client.hmset "actions:#{aid}", action
      if not err and not val # creating new action
        client.rpush "projects:#{pid}:#{type}", aid
        client.rpush "canvases:#{data.canvasId}:#{type}", aid if data.canvasId

        if type is 'comment'
          client.incr "actions:#{data.canvasId}:next", (err, commentNumber) ->
            action.number = commentNumber
            action.newAction = true # this won't go into db, just a marker for top level code
            client.hset "actions:#{aid}", "number", commentNumber
            if data.element.texts and data.element.texts.length
              return tools.asyncParallel data.element.texts, (text) ->
                return db.commentTexts.add text, ->
                  return tools.asyncDone data.element.texts, ->
                    return tools.asyncOpt fn, null, action
            else
              return tools.asyncOpt fn, null, action
        else
          return tools.asyncOpt fn, null, action

      return tools.asyncOpt fn, null, action

  mod.delete = (aid, fn) ->
    await db.actions.findById aid, defer(err, action)
    return tools.asyncOpt fn, err, null if err or not action

    client.lrem "projects:#{action.project}:#{action.type}", 0, aid
    client.lrem "canvases:#{action.canvasId}:#{action.type}", 0, aid if action.canvasId

    if action.type is 'comment'
      await client.lrange "comments:#{aid}:texts", 0, -1, defer(err, commentTextsIds)
      return tools.asyncOpt fn, err, null if err

      deleteCommentText = (commentTextId, autocb) -> await db.commentTexts.remove commentTextId, defer()
      await deleteCommentText commentTextId, defer() for commentTextId in commentTextsIds

    client.del "actions:#{aid}", fn

  mod.findById = (aid, fn) ->
    client.hgetall "actions:#{aid}", fn

  mod.getProjectActions = (pid, type, fn) ->
    negativeActionsBufferSize = -cfg.ACTIONS_BUFFER_SIZE
    client.lrange "projects:#{pid}:#{type}", negativeActionsBufferSize, -1, (err, array) ->
      if not err and array and array.length
        actions = []
        return tools.asyncParallel array, (aid) ->
          client.hgetall "actions:#{aid}", (err, action) ->
            return tools.asyncOpt fn, err, [] if err

            db.users.findById action.owner, (err, user) ->
              return tools.asyncOpt fn, err, [] if err

              action.owner = user
              actions.push action
              return tools.asyncDone array, ->
                return tools.asyncOpt fn, null, actions
      return tools.asyncOpt fn, err, []

  mod.getElements = (cid, type, fn) ->
    client.lrange "canvases:#{cid}:#{type}", 0, -1, (err, actions) ->
      return tools.asyncOpt fn, null, [] if not actions or not actions.length

      if not err
        fetchedActions = []

        return tools.asyncParallel actions, (aid) ->
          client.hgetall "actions:#{aid}", (err, action) ->
            fetchedAction = JSON.parse(action.data)
            fetchedAction.number = action.number
            return tools.asyncOpt fn, err, [] if err

            if type is 'comment'
              return db.commentTexts.index fetchedAction.elementId, (err, texts) ->
                fetchedAction.texts = texts
                fetchedActions.push fetchedAction
                tools.asyncDone actions, ->
                  tools.asyncOpt fn, null, fetchedActions
            else
              fetchedActions.push fetchedAction
              tools.asyncDone actions, ->
                tools.asyncOpt fn, null, fetchedActions

      return tools.asyncOpt fn, err, []

  return mod
