exports.setUp = (client, db) =>

  mod = {}

  mod.index = (elementId, fn) =>
    client.lrange "comments:#{elementId}:texts", 0, -1, (err, array) =>
      if not err and array and array.length
        texts = []
        return @tools.asyncParallel array, (textId) =>
          client.hgetall "texts:#{textId}", (err, text) =>
            texts.push text
            @tools.asyncDone array, =>
              @tools.asyncOpt fn, null, texts
      return @tools.asyncOpt fn, err, []

  # comment text may be restored after undo, in this case we consider this comment text as not new.
  mod.add = (element, isNew, fn) =>
    element.time = Date.now()
    client.hmset "texts:#{element.elementId}", element
    client.rpush "comments:#{element.commentId}:texts", element.elementId
    db.activities.addForAllInProject element.pid, 'newComment', element.owner, [element.owner], {commentTextId: element.elementId} if isNew
    return @tools.asyncOpt fn, null, element

  mod.update = (elementId, text, fn) =>
    client.hset "texts:#{elementId}", "text", text

  mod.findById = (elementId, fn) =>
    client.hgetall "texts:#{elementId}", fn

  mod.remove = (elementId, fn) =>
    db.texts.findById elementId, (err, text) =>
      return @tools.asyncOpt fn, err, null if err or not text
      client.lrem "comments:#{text.commentId}:texts", 0, elementId
      client.lrem "projects:#{text.pid}:todo", 0, elementId
      client.del "texts:#{elementId}", fn

  mod.getProjectTodos = (pid, count, fn) =>
    client.lrange "projects:#{pid}:todo", 0, count, (err, array) =>
      if not err and array and array.length
        todos = []
        return @tools.asyncParallel array, (textId) =>
          client.hgetall "texts:#{textId}", (err, todo) =>
            todos.push todo
            @tools.asyncDone array, =>
              @tools.asyncOpt fn, null, todos
      return @tools.asyncOpt fn, err, []

  mod.getProjectTodosCount = (pid, fn) =>
    client.llen "projects:#{pid}:todo", (err, len) =>
      return @tools.asyncOpt fn, err, len

  mod.markAsTodo = (elementId, fn) =>
    db.texts.findById elementId, (err, text) =>
      if not err and text
        client.lpush "projects:#{text.pid}:todo", elementId
        client.hset "texts:#{elementId}", "todo", true
        db.activities.addForAllInProject text.pid, 'newTodo', text.owner, [text.owner], {commentTextId: text.elementId}
        return @tools.asyncOpt fn, err, null
      return @tools.asyncOpt fn, err, null

  mod.resolveTodo = (elementId, fn) =>
    db.texts.findById elementId, (err, text) =>
      if not err and text
        client.lrem "projects:#{text.pid}:todo", 0, elementId
        client.hset "texts:#{elementId}", "resolved", true
        db.activities.addForAllInProject text.pid, 'todoResolved', text.owner, [text.owner], {commentTextId: text.elementId}
        return @tools.asyncOpt fn, err, null
      return @tools.asyncOpt fn, err, null

  mod.reopenTodo = (elementId, fn) =>
    db.texts.findById elementId, (err, text) =>
      if not err and text
        client.lpush "projects:#{text.pid}:todo", elementId
        client.hdel "texts:#{elementId}", "resolved"
        db.activities.addForAllInProject text.pid, 'todoReopened', text.owner, [text.owner], {commentTextId: text.elementId}
        return @tools.asyncOpt fn, err, null
      return @tools.asyncOpt fn, err, null

  return mod
