exports.add = (pid, file, time, fn) =>
  return @client.llen "projects:#{pid}:canvases", (err, count) =>
    return @client.incr 'canvases:next', (err, cid) =>
      unless err
        canvas =
          id: cid
          createdAt: Date.now()
          project: pid
        canvas.time = time if time
        canvas.file = file.id if file
        canvas.initialized = true if count > 0
        canvas.position = count
        if file and file.name.trim().length > 0
          canvas.name = file.name
        else
          canvas.name = "Canvas #{count + 1}"
        @client.hmset "canvases:#{cid}", canvas, @tools.logError
        @client.rpush "projects:#{pid}:canvases", cid
        return @tools.asyncOpt fn, null, canvas
      return @tools.asyncOpt fn, err, null

exports.initFirst = (pid, fn) =>
  return @client.lindex "projects:#{pid}:canvases", 0, (err, val) =>
    @client.hset "canvases:#{val}", "initialized", "true"
    return @tools.asyncOpt fn, err, val

exports.get = (cid, fn) =>
  @client.hgetall 'canvases:' + cid, fn

exports.index = (pid, fn) =>
  @client.sort "projects:#{pid}:canvases", "by", "canvases:*=>position", (err, array) =>
    if not err and array and array.length
      canvases = []
      return @tools.asyncParallel array, (cid, index) =>
        @db.canvases.get cid, (err, canvas) =>
          if not err and canvas
            @db.files.findById canvas.file, (err, file) =>
              canvas.file = file
              @db.elements.index cid, (err, elements) =>
                canvas.elements = elements
                @db.comments.index cid, (err, comments) =>
                  canvas.comments = comments
                  unless err
                    canvases[index] = canvas
                  return @tools.asyncDone array, =>
                    return @tools.asyncOpt fn, null, canvases
    return @tools.asyncOpt fn, err, []

exports.reorder = (pid, cid, toPos, fn) =>
  @db.canvases.get cid, (err, moveCanvas) =>
    fromPos = moveCanvas.position
    return @tools.asyncOpt fn, err, null if fromPos is toPos
    @client.lrange "projects:#{pid}:canvases", 0, -1, (err, array) =>
      if not err and array and array.length
        return @tools.asyncParallel array, (canvasId) =>
          return @db.canvases.get canvasId, (err, canvas) =>
            if "#{canvasId}" is "#{cid}"
              @db.canvases.setProperties canvas.id, position: toPos
              return @tools.asyncDone array, => return @tools.asyncOpt fn, null, null

            if fromPos < toPos
              if fromPos < canvas.position <= toPos
                @db.canvases.setProperties canvas.id, position: parseInt(canvas.position) - 1
            else
              if toPos <= canvas.position < fromPos
                @db.canvases.setProperties canvas.id, position: parseInt(canvas.position) + 1

            return @tools.asyncDone array, => return @tools.asyncOpt fn, null, null
      return @tools.asyncOpt fn, err, null

exports.clear = (cid) =>
  @db.canvases.deleteElements cid
  @db.canvases.deleteComments cid

exports.delete = (cid, fn) =>
  @db.canvases.get cid, (err, canvas)=>
    if not err and canvas
      @client.lrange "projects:#{canvas.project}:canvases", 0, -1, (err, canvases) =>
        if not err and canvases and canvases.length
          if canvases.length <= 1
            @db.canvases.clear cid
            @client.hdel "canvases:#{cid}", "file"
            @client.hset "canvases:#{cid}", "initialized", "false"
            return @tools.asyncOpt fn, null, null
          else
            @client.lrem "projects:#{canvas.project}:canvases", 0, cid
            @db.canvases.clear cid
            return @client.del "canvases:#{cid}", cid
    return @tools.asyncOpt fn, null, null

exports.deleteElements = (cid, fn) =>
  @client.lrange "canvases:#{cid}:elements", 0, -1, (err, array) =>
    return @tools.asyncOpt fn, null, null if not array or not array.length
    return @tools.asyncParallel array, (aid) =>
      @db.elements.delete aid, fn
      return @tools.asyncDone array, =>
        return @tools.asyncOpt fn, null, null

exports.deleteComments = (cid, fn) =>
  @client.lrange "canvases:#{cid}:comments", 0, -1, (err, array) =>
    return @tools.asyncOpt fn, null, null if not array or not array.length
    return @tools.asyncParallel array, (aid) =>
      @db.comments.delete aid, fn
      return @tools.asyncDone array, =>
        return @tools.asyncOpt fn, null, null

exports.setProperties = (cid, properties) =>
  @client.hmset "canvases:#{cid}", properties, @tools.logError

exports.commentNumber = (cid, fn) =>
  @client.hget "canvases:#{cid}", 'nextComment', fn

exports.getProject = (cid, fn) =>
  @client.hget "canvases:#{cid}", 'project', fn
