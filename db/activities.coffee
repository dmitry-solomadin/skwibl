tools = require '../tools'
cfg = require '../config'
announce = require('socket.io-announce') {namespace: '/activities'}

exports.setUp = (client, db) ->

  mod = {}

  # type is 'projectInvite' or ...
  mod.add = (pid, owner, type, invitingUserId, fn) ->
    client.incr 'activities:next', (err, aid) ->
      if not err
        activity = {}
        activity.id = aid
        activity.project = pid
        activity.owner = owner
        activity.type = type
        activity.time = new Date().getTime()
        activity.status = 'new'
        activity.inviting = invitingUserId
        client.hmset "activities:#{aid}", activity

        client.rpush "users:#{owner}:activities", aid
        announce.in("activities#{owner}").emit 'new'
        return tools.asyncOpt fn, null, activity

      return tools.asyncOpt fn, err, null

  mod.getAllNew = (uid, fn) ->
    mod.index uid, fn, (activity) ->
      return activity.status is 'new'

  mod.index = (uid, fn, filter) ->
    client.lrange "users:#{uid}:activities", -cfg.ACTIONS_BUFFER_SIZE, -1, (err, array) ->
      if not err and array and array.length
        activities = []
        return tools.asyncParallel array, (aid) ->
          return client.hgetall "activities:#{aid}", (err, activity) ->
            if err
              return tools.asyncOpt fn, err, []
            if filter
              if filter activity
                activities.push activity
            else
              activities.push activity
            return tools.asyncDone array, ->
              return tools.asyncOpt fn, null, activities
      return tools.asyncOpt fn, err, []

  mod.getDataActivity = (aid, fn) ->
    return client.hgetall "activities:#{aid}",  (err, activity) ->
      return tools.asyncOpt fn, err, [] if err
      activities = []
      activities.push activity
      return mod.getDataActivities activities, (err) ->
        return tools.asyncOpt fn, err, activity

  mod.getDataActivities = (activities, fn) ->
    return mod.getProjectForActivities activities, (err) ->
      unless err
        return mod.getUserForActivities activities, (err) ->
          fn err
      return fn err

  mod.getProjectForActivities = (activities, fn) ->
    return tools.asyncParallel activities, (activity) ->
      return db.projects.getData activity.project, (err, project) ->
        if not err and project
          activity.project = project
          return tools.asyncDone activities, ->
            return tools.asyncOpt fn, null, null
        return tools.asyncOpt fn, err, []

  mod.getUserForActivities = (activities, fn) ->
    return tools.asyncParallel activities, (activity) ->
      return db.users.findById activity.inviting, (err, user) ->
        if not err and user
          activity.inviting = user
          return tools.asyncDone activities, ->
            return tools.asyncOpt fn, null, null
        return tools.asyncOpt fn, err, []

  return mod
