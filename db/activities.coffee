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

  mod.getDataActivity = (aid, done) ->
    return client.hgetall "activities:#{aid}",  (err, activity) ->
      if err
        return tools.asyncOpt done, err, []
      activities = []
      activities.push activity
      mod.getDataActivities activities, (err) ->
        done err, activity

  mod.getDataActivities = (activities, done) ->
    return mod.getProjectForActivities activities, (err) ->
      if not err
        return mod.getUserForActivities activities, (err) ->
          done err
      return done err

  mod.getProjectForActivities = (activities, done) ->
    return tools.asyncParallel activities,  (left, activity) ->
      return db.projects.getData activity.project, (err, project) ->
        if not err and project
          activity.project = project
          fn = -> done()
          return tools.asyncDone left, ->
            return tools.asyncOpt fn, null, null
        gn = -> done(err)
        return tools.asyncOpt gn, err, []

  mod.getUserForActivities = (activities, done) ->
    return tools.asyncParallel activities, (left, activity) ->
      return db.users.findById activity.inviting, (err, user) ->
        if not err and user
          activity.inviting = user
          fn = -> done()
          return tools.asyncDone left, ->
            return tools.asyncOpt fn, null, null
        gn = -> done(err)
        return tools.asyncOpt gn, err, []

  return mod
