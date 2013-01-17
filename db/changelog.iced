tools = require '../tools'

exports.setUp = (client, db) ->

  mod = {}

  mod.add = (pid, uid, type, additionalInfo, fn) ->
    client.incr 'changelog:next', (err, clid) ->
      if not err
        changelog = {}
        changelog.id = clid
        changelog.pid = pid
        changelog.type = type
        changelog.time = Date.now()
        changelog.initiator = uid
        changelog.additionalInfo = JSON.stringify additionalInfo
        client.hmset "changelog:#{clid}", changelog
        client.rpush "projects:#{pid}:changelog", clid
        return tools.asyncOpt fn, null, changelog
      return tools.asyncOpt fn, err, null

  mod.index = (pid, fn) ->
    client.sort "projects:#{pid}:changelog", "by", "changelog:*->time", "desc", (err, changelogIds) ->
      if not err and changelogIds and changelogIds.length
        changelog = []
        return tools.asyncParallel changelogIds, (clid) ->
          return client.hgetall "changelog:#{clid}", (err, changelogEntry)->
            return tools.asyncOpt fn, err, [] if err
            return db.users.findById changelogEntry.initiator, (err, user) ->
              return tools.asyncOpt fn, err, [] if err
              changelogEntry.initiator = user
              changelogEntry.additionalInfo = JSON.parse changelogEntry.additionalInfo
              changelog.push changelogEntry
              if changelogEntry.additionalInfo.commentTextId
                return db.comments.findById changelogEntry.additionalInfo.commentTextId, (err, text) ->
                  changelogEntry.commentText = text
                  return tools.asyncDone changelogIds, -> tools.asyncOpt fn, null, changelog
              return tools.asyncDone changelogIds, -> tools.asyncOpt fn, null, changelog
      return tools.asyncOpt fn, err, []

  return mod
