tools = require '../tools'
cfg = require '../config'

exports.setUp = (client, db) ->

  mod = {}

  mod.updateAction = (aid, action, create, fn) ->
    pid = action.project
    type = action.type
    canvas = action.canvasId
    client.hmset "actions:#{aid}", action
    unless create # creating new action
      action.new = create
      client.rpush "projects:#{pid}:#{type}", aid
      client.rpush "canvases:#{canvas}:#{type}", aid if canvas
      return tools.asyncOpt fn, null, action
    return tools.asyncOpt fn, null, action

  mod.update = (pid, owner, type, data, fn) ->
    element = data.element
    canvasId = data.canvasId
    aid = element.elementId
    action = {}
    action.project = pid
    action.owner = owner
    action.type = type
    action.canvasId = canvasId if canvasId
    action.time = Date.now()
    action.data = JSON.stringify(element)
    console.log data
    return client.exists "actions:#{aid}", (err, val) ->
      number = parseInt data.number if val and data.number
      action.number = number unless isNaN number
      if type is 'comment' and not val
        return client.hincrby "canvases:#{canvasId}", 'nextComment', 1, (err, cid) ->
          action.number = cid
          if element.texts and element.texts.length
            tools.asyncParallel element.texts, (text) ->
              db.comments.add text
          return db.actions.updateAction(aid, action, val, fn)
      return db.actions.updateAction(aid, action, val, fn)

  mod.delete = (aid, fn) ->
    db.actions.findById aid, (err, action) ->
      if err or not action
        return tools.asyncOpt fn, err, null
      client.del "actions:#{aid}", fn
      client.lrem "projects:#{action.project}:#{action.type}", 0, aid
      client.lrem "canvases:#{action.canvasId}:#{action.type}", 0, aid if action.canvasId
      if action.type is 'comment'
        client.lrange "comments:#{aid}:texts", 0, -1, (err, array) ->
          return tools.asyncOpt fn, err, null if err
          return tools.asyncParallel array, (tid) ->
            db.comments.remove tid
            return tools.asyncDone array, ->
              return tools.asyncOpt fn, null, aid
      return tools.asyncOpt fn, null, aid

  mod.findById = (aid, fn) ->
    client.hgetall "actions:#{aid}", fn

  mod.getElements = (cid, type, fn) ->
    client.lrange "canvases:#{cid}:#{type}", 0, -1, (err, array) ->
      return tools.asyncOpt fn, null, [] if not array or not array.length
      if not err
        fetchedActions = []
        return tools.asyncParallel array, (aid) ->
          client.hgetall "actions:#{aid}", (err, action) ->
            fetchedAction = JSON.parse(action.data)
            fetchedAction.number = action.number
            return tools.asyncOpt fn, err, [] if err
            if type is 'comment'
              return db.comments.index fetchedAction.elementId, (err, texts) ->
                fetchedAction.texts = texts
                fetchedActions.push fetchedAction
                tools.asyncDone array, ->
                  tools.asyncOpt fn, null, fetchedActions
            else
              fetchedActions.push fetchedAction
              tools.asyncDone array, ->
                tools.asyncOpt fn, null, fetchedActions
      return tools.asyncOpt fn, err, []

  return mod
