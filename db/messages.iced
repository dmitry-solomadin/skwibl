exports.update = (pid, owner, data, fn) =>
  mid = data.elementId
  msg = {}
  msg.project = pid
  msg.owner = owner
  msg.time = Date.now()
  msg.message = data.msg
  return @client.exists "messages:#{mid}", (err, exists) =>
    @client.hmset "messages:#{mid}", msg, @tools.logError
    unless exists # creating new message
      @client.rpush "projects:#{pid}:messages", mid
      return @tools.asyncOpt fn, err, msg
    return @tools.asyncOpt fn, err, msg

exports.delete = (mid, fn) =>
  @db.messages.findById mid, (err, msg) =>
    if err or not msg
      return @tools.asyncOpt fn, err, null
    @client.del "messages:#{mid}", fn
    @client.lrem "projects:#{msg.project}:messages", 0, mid
    return @tools.asyncOpt fn, null, mid

exports.findById = (mid, fn) =>
  @client.hgetall "messages:#{mid}", fn

exports.getProjectMessages = (pid, fn) =>
  @client.lrange "projects:#{pid}:messages", 0, -1, (err, array) =>
    if not err and array and array.length
      messages = []
      return @tools.asyncParallel array, (mid) =>
        @client.hgetall "messages:#{mid}", (err, msg) =>
          @db.contacts.getInfo msg.owner, (err, user) =>
            if not err and user
              msg.owner = user
              messages.push msg
            return @tools.asyncDone array, =>
              return @tools.asyncOpt fn, null, messages
    return @tools.asyncOpt fn, err, []

exports.getOwner = (mid, fn) =>
  @client.hget "messages:#{mid}", 'owner'
