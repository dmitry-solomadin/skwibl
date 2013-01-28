tools = require '../tools'
cfg = require '../config'

exports.setUp = (client, db) ->

  mod = {}

  mod.updateComment = (eid, element, create, fn) ->
    pid = element.project
    canvas = element.canvasId
    client.hmset "comments:#{eid}", element
    unless create # creating new element
      client.rpush "canvases:#{canvas}:comments", eid
      return tools.asyncOpt fn, null, element
    return tools.asyncOpt fn, null, element

  mod.update = (pid, owner, data, fn) ->
    canvasId = data.canvasId
    dataElement = data.element
    eid = dataElement.elementId
    element = {}
    element.project = pid
    element.owner = owner
    element.canvasId = canvasId
    element.time = Date.now()
    element.data = JSON.stringify(dataElement)
    return client.exists "comments:#{eid}", (err, val) ->
      number = parseInt data.number if val and data.number
      element.number = number unless isNaN number
      unless val
        return client.hincrby "canvases:#{canvasId}", 'nextComment', 1, (err, cid) ->
          element.number = cid
          if element.texts and element.texts.length
            tools.asyncParallel element.texts, (text) ->
              db.texts.add text
          return db.comments.updateComment(eid, element, val, fn)
      return db.comments.updateComment(eid, element, val, fn)

  mod.delete = (eid, fn) ->
    db.comments.findById eid, (err, element) ->
      if err or not element
        return tools.asyncOpt fn, err, null
      client.del "comments:#{eid}", fn
      client.lrem "canvases:#{element.canvasId}:comments", 0, eid
      client.lrange "comments:#{eid}:texts", 0, -1, (err, array) ->
        return tools.asyncOpt fn, err, null if err
        return tools.asyncParallel array, (tid) ->
          db.texts.remove tid
          return tools.asyncDone array, ->
            return tools.asyncOpt fn, null, eid

  mod.findById = (eid, fn) ->
    client.hgetall "comments:#{eid}", fn

  mod.index = (cid, fn) ->
    client.lrange "canvases:#{cid}:comments", 0, -1, (err, array) ->
      return tools.asyncOpt fn, null, [] if not array or not array.length
      if not err
        elements = []
        return tools.asyncParallel array, (eid) ->
          client.hgetall "comments:#{eid}", (err, element) ->
            elementData = JSON.parse(element.data)
            elementData.number = element.number
            return tools.asyncOpt fn, err, [] if err
            return db.texts.index elementData.elementId, (err, texts) ->
              elementData.texts = texts
              elements.push elementData
              return tools.asyncDone array, ->
                return tools.asyncOpt fn, null, elements
      return tools.asyncOpt fn, err, []

  mod.getCanvas = (eid, fn) ->
    client.hget "comments:#{eid}", 'canvasId', fn

  return mod
