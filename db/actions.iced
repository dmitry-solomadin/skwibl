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
    action.time = Date()
    action.data = JSON.stringify(data.element)
    return client.exists "actions:#{aid}", (err, val) ->
      client.hmset "actions:#{aid}", action
      if not err and not val # creating new action
        client.rpush "projects:#{pid}:#{type}", aid
        client.rpush "canvases:#{data.canvasId}:#{type}", aid if data.canvasId
        if type is 'comment'
          client.incr "actions:#{data.canvasId}:next", (err, cid) ->
            action.number = cid
            action.newAction = true # this won't go into db, just a marker for top level code
            client.hset "actions:#{aid}", "number", cid
            if data.element.texts and data.element.texts.length
              return tools.asyncParallel data.element.texts, (text) ->
                return db.comments.add text, ->
                  return tools.asyncDone data.element.texts, ->
                    return tools.asyncOpt fn, null, action
            else
              return tools.asyncOpt fn, null, action
        else
          return tools.asyncOpt fn, null, action
      return tools.asyncOpt fn, null, action

  mod.delete = (aid, fn) ->
    db.actions.findById aid, (err, action) ->
      if err or not action
        return tools.asyncOpt fn, err, null
      client.del "actions:#{aid}", fn unless err
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

  mod.getProjectActions = (pid, type, fn) ->
    client.lrange "projects:#{pid}:#{type}", -cfg.ACTIONS_BUFFER_SIZE, -1, (err, array) ->
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
    client.lrange "canvases:#{cid}:#{type}", 0, -1, (err, array) ->
      return tools.asyncOpt fn, null, [] if not array or not array.length
      if not err
        actions = []
        return tools.asyncParallel array, (aid) ->
          client.hgetall "actions:#{aid}", (err, action) ->
            action = JSON.parse(action.data)
            action.number = action.number
            return tools.asyncOpt fn, err, [] if err
            if type is 'comment'
              return db.comments.index action.elementId, (err, texts) ->
                action.texts = texts
                actions.push action
                tools.asyncDone array, ->
                  tools.asyncOpt fn, null, actions
            else
              actions.push action
              tools.asyncDone array, ->
                tools.asyncOpt fn, null, actions
      return tools.asyncOpt fn, err, []

  return mod
