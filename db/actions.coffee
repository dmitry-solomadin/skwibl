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
      if not err and not val # creating new action
        client.rpush "projects:#{pid}:#{type}", aid
        client.rpush "canvases:#{data.canvasId}:#{type}", aid if data.canvasId

        if data.element.texts and data.element.texts.length
          tools.asyncParallel data.element.texts, (text) ->
            db.commentTexts.add text, ->
              tools.asyncDone data.element.texts, ->
                tools.asyncOpt fn, null, action

      tools.asyncOpt fn, null, action

  mod.delete = (aid, fn) ->
    db.actions.findById aid, (err, action) ->
      return tools.asyncOpt fn, err, null if err or not action

      client.lrem "projects:#{action.project}:#{action.type}", 0, aid
      client.lrem "canvases:#{action.canvasId}:#{action.type}", 0, aid if action.canvasId

      if action.type is 'comment'
        client.lrange "comments:#{aid}:texts", 0, -1, (err, commentTextsIds) ->
          if not err and commentTextsIds and commentTextsIds.length
            return tools.asyncParallel commentTextsIds, (commentTextId) ->
              db.commentTexts.remove commentTextId, ->
                return tools.asyncOpt fn, null, null

              return tools.asyncDone commentTextsIds, ->
                return client.del "actions:#{aid}", fn
          return tools.asyncOpt fn, null, null
      else
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
