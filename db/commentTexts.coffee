tools = require '../tools'
cfg = require '../config'

exports.setUp = (client, db) ->
  mod = {}

  mod.index = (eid, fn) ->
    client.sort "comments:#{eid}:texts", "by", "texts:*->time", (err, textsIds) ->
      if not err and textsIds and textsIds.length
        texts = []

        return tools.asyncParallel textsIds, (textId) ->
          client.hgetall "texts:#{textId}", (err, text) ->
            texts.push text

            tools.asyncDone textsIds, ->
              tools.asyncOpt fn, null, texts

      return tools.asyncOpt fn, err, []

  mod.add = (element, fn) ->
    element.time = new Date().getTime()
    client.hmset "texts:#{element.elementId}", element
    client.rpush "comments:#{element.commentId}:texts", element.elementId
    return tools.asyncOpt fn, null, element

  mod.update = (elementId, text, fn) ->
    client.hset "texts:#{elementId}", "text", text

  mod.findById = (elementId, fn) ->
    client.hgetall "texts:#{elementId}", fn

  mod.remove = (elementId, fn) ->
    db.commentTexts.findById elementId, (err, commentText) ->
      return tools.asyncOpt fn, err, null if err or not commentText

      client.lrem "comments:#{commentText.commentId}:texts", 0, elementId
      client.srem "projects:#{commentText.pid}:todo", elementId
      client.del "texts:#{elementId}", fn

  mod.getProjectTodos = (pid, count, fn) ->
    client.sort "projects:#{pid}:todo", "by", "texts:*->time", "limit", "0", count, (err, textsIds) ->
      if not err and textsIds and textsIds.length
        todos = []
        return tools.asyncParallel textsIds, (textId) ->
          client.hgetall "texts:#{textId}", (err, todo) ->
            todos.push todo

            tools.asyncDone textsIds, ->
              tools.asyncOpt fn, null, todos

      return tools.asyncOpt fn, err, []

  mod.markAsTodo = (elementId, fn) ->
    db.commentTexts.findById elementId, (err, commentText) ->
      if not err and commentText
        client.sadd "projects:#{commentText.pid}:todo", elementId
        client.hset "texts:#{elementId}", "todo", true
        return tools.asyncOpt fn, err, null

      return tools.asyncOpt fn, err, null

  mod.resolveTodo = (elementId, fn) ->
    db.commentTexts.findById elementId, (err, commentText) ->
      if not err and commentText
        client.srem "projects:#{commentText.pid}:todo", elementId
        client.hset "texts:#{elementId}", "resolved", true
        return tools.asyncOpt fn, err, null

      return tools.asyncOpt fn, err, null

  mod.reopenTodo = (elementId, fn) ->
    db.commentTexts.findById elementId, (err, commentText) ->
      if not err and commentText
        client.sadd "projects:#{commentText.pid}:todo", elementId
        client.hdel "texts:#{elementId}", "resolved"
        return tools.asyncOpt fn, err, null

      return tools.asyncOpt fn, err, null

  return mod