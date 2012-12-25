tools = require '../tools'
cfg = require '../config'

exports.setUp = (client, db) ->
  mod = {}

  mod.index = (eid, fn) ->
    client.sort "comments:#{eid}:texts", "by", "texts:*->time", (err, array) ->
      if not err and array and array.length
        texts = []
        return tools.asyncParallel array, (textId) ->
          client.hgetall "texts:#{textId}", (err, text) ->
            texts.push text
            tools.asyncDone array, ->
              tools.asyncOpt fn, null, texts
      return tools.asyncOpt fn, err, []

  mod.add = (element, fn) ->
    element.time = Date.now()
    client.hmset "texts:#{element.elementId}", element
    client.rpush "comments:#{element.commentId}:texts", element.elementId
    return tools.asyncOpt fn, null, element

  mod.update = (elementId, text, fn) ->
    client.hset "texts:#{elementId}", "text", text

  mod.findById = (elementId, fn) ->
    client.hgetall "texts:#{elementId}", fn

  mod.remove = (elementId, fn) ->
    db.comments.findById elementId, (err, text) ->
      return tools.asyncOpt fn, err, null if err or not text
      client.lrem "comments:#{text.commentId}:texts", 0, elementId
      client.srem "projects:#{text.pid}:todo", elementId
      client.del "texts:#{elementId}", fn

  mod.getProjectTodos = (pid, count, fn) ->
    client.sort "projects:#{pid}:todo", "by", "texts:*->time", "limit", "0", count, (err, array) ->
      if not err and array and array.length
        todos = []
        return tools.asyncParallel array, (textId) ->
          client.hgetall "texts:#{textId}", (err, todo) ->
            todos.push todo
            tools.asyncDone array, ->
              tools.asyncOpt fn, null, todos
      return tools.asyncOpt fn, err, []

  mod.markAsTodo = (elementId, fn) ->
    db.comments.findById elementId, (err, text) ->
      if not err and text
        client.sadd "projects:#{text.pid}:todo", elementId
        client.hset "texts:#{elementId}", "todo", true
        return tools.asyncOpt fn, err, null
      return tools.asyncOpt fn, err, null

  mod.resolveTodo = (elementId, fn) ->
    db.comments.findById elementId, (err, text) ->
      if not err and text
        client.srem "projects:#{text.pid}:todo", elementId
        client.hset "texts:#{elementId}", "resolved", true
        return tools.asyncOpt fn, err, null
      return tools.asyncOpt fn, err, null

  mod.reopenTodo = (elementId, fn) ->
    db.comments.findById elementId, (err, text) ->
      if not err and text
        client.sadd "projects:#{text.pid}:todo", elementId
        client.hdel "texts:#{elementId}", "resolved"
        return tools.asyncOpt fn, err, null
      return tools.asyncOpt fn, err, null

  return mod