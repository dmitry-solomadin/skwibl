tools = require '../tools'
cfg = require '../config'
announce = require('socket.io-announce') {namespace: '/activities'}

exports.setUp = (client, db) ->

  mod = {}

  mod.add = (project, owner, type, invitingUserId, fn) ->
    client.incr 'activities:next', (err, val) ->
      if not err
        activity = {}
        activity.id = val
        activity.project = project
        activity.owner = owner
        activity.type = type
        activity.time = new Date().getTime()
        activity.status = 'new'
        activity.inviting = invitingUserId
        client.hmset "activities:#{val}", activity
        # stub for #103 and #99
        # cliend.sadd("project:pid:invitedUsers", owner);
        client.rpush "users:#{owner}:activities", val
        announce.in("activities#{owner}").emit 'new'
        return tools.asyncOpt fn, null, activity
      return tools.asyncOpt fn, err, null

  mod.getAllNew = (id, fn) ->
    mod.get id, fn, (activity) ->
      return activity.status is 'new'

  mod.get = (id, fn, filter) ->
    client.lrange "users:#{id}:activities", -cfg.ACTIONS_BUFFER_SIZE, -1, (err, array) ->
      if not err and array and array.length
        activities = []
        return tools.asyncParallel array, (left, aid) ->
          return client.hgetall "activities:#{aid}", (err, activity) ->
            if err
              return tools.asyncOpt fn, err, []
            if filter
              if filter activity
                activities.push activity
            else
              activities.push activity
            return tools.asyncDone left, ->
              return tools.asyncOpt fn, null, activities
      return tools.asyncOpt fn, err, []

  mod.getDataActivity = (aid, fn) ->
    return client.hgetall "activities:#{aid}",  (err, activity) ->
      return tools.asyncOpt fn, err, [] if err
      activities = []
      activities.push activity
      mod.getDataActivities activities, (err) -> fn err, activity

  mod.getDataActivities = (activities, fn) ->
    return mod.getProjectForActivities activities, (err) ->
      unless err
        return mod.getUserForActivities activities, (err) ->
          fn err
      return fn err

  mod.getProjectForActivities = (activities, fn) ->
    return tools.asyncParallel activities,  (left, activity) ->
      return db.projects.getData activity.project, (err, project) ->
        if not err and project
          activity.project = project
          return tools.asyncDone left, ->
            return tools.asyncOpt fn, null, null
        return tools.asyncOpt fn, err, []

  mod.getUserForActivities = (activities, fn) ->
    return tools.asyncParallel activities, (left, activity) ->
      return db.users.findById activity.inviting, (err, user) ->
        if not err and user
          activity.inviting = user
          return tools.asyncDone left, ->
            return tools.asyncOpt fn, null, null
        return tools.asyncOpt fn, err, []

  return mod
