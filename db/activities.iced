helpers = require '../helpers'
announce = require('socket.io-announce') {namespace: '/activities'}

# types are: 'projectInvite', 'projectJoin', 'projectLeft', 'newComment',
# 'newTodo', 'todoResolved', 'todoReopened', 'fileUpload'
exports.add = (pid, ownerId, type, uid, additionalInfo, fn) =>
  @client.incr 'activities:next', (err, aid) =>
    if not err
      activity = {}
      activity.id = aid
      activity.project = pid
      activity.owner = ownerId
      activity.type = type
      activity.time = Date.now()
      activity.status = 'new'
      activity.inviting = uid
      activity.additionalInfo = JSON.stringify additionalInfo
      @client.hmset "activities:#{aid}", activity
      @client.rpush "users:#{ownerId}:activities", aid
      announce.in("activities#{ownerId}").emit 'new'
      if type is 'projectInvite'
        @db.projects.findById pid, (err, project) =>
          @db.users.findById uid, (err, invitor) =>
            @db.users.findById ownerId, (err, owner) =>
              @smtp.prjInviteActivity owner, invitor, project
      return @tools.asyncOpt fn, null, activity
    return @tools.asyncOpt fn, err, null

exports.addForAllInProject = (pid, type, uid, except, additionalInfo, fn) =>
  @db.changelog.add pid, uid, type, additionalInfo if helpers.activities.isChangeLoggable type
  onDone = (err) => @tools.asyncOpt fn, err, null
  @db.projects.getUsers pid, (err, users) =>
    @tools.asyncOpt fn, err, null if err or not users or not users.length
    return @tools.asyncParallel users, (user) =>
      if except and except.length
        # continue to the next user if the user is in except
        return onDone() for exceptId in except when exceptId is user.id
      return @db.activities.add pid, user.id, type, uid, additionalInfo, (err) =>
        onDone err

# todo consider refactoring in scope of #138
exports.getAllNew = (uid, fn) =>
  exports.index uid, fn, (activity) =>
    return activity.status is 'new'

exports.findById = (aid, fn) =>
  @client.hgetall "activities:#{aid}", fn

exports.delete = (aid, fn) =>
  @db.activities.findById aid, (err, activity) =>
    if not err and activity
      @client.lrem "users:#{activity.owner}:activities", 0, aid
      @client.del "activities:#{aid}"
    return @tools.asyncOpt fn, err, activity

exports.index = (uid, fn, filter) =>
  @client.lrange "users:#{uid}:activities", -@cfg.ACTIONS_BUFFER_SIZE, -1, (err, array) =>
    if not err and array and array.length
      activities = []
      return @tools.asyncParallel array, (aid) =>
        return @client.hgetall "activities:#{aid}", (err, activity) =>
          if err
            return @tools.asyncOpt fn, err, []
          if filter
            if filter activity
              activities.push activity
          else
            activities.push activity
          return @tools.asyncDone array, =>
            return @tools.asyncOpt fn, null, activities
    return @tools.asyncOpt fn, err, []

exports.getDataActivity = (aid, fn) =>
  return @client.hgetall "activities:#{aid}",  (err, activity) =>
    return @tools.asyncOpt fn, err, [] if err
    activities = []
    activities.push activity
    return exports.getDataActivities activities, (err) =>
      return @tools.asyncOpt fn, err, activity

exports.getDataActivities = (activities, fn) =>
  return exports.getProjectForActivities activities, (err) =>
    unless err
      return exports.getUserForActivities activities, (err) =>
        fn err
    return fn err

exports.getProjectForActivities = (activities, fn) =>
  return @tools.asyncParallel activities, (activity) =>
    return @db.projects.getData activity.project, (err, project) =>
      unless err
        activity.project = project
        return @tools.asyncDone activities, =>
          return @tools.asyncOpt fn, null, null
      return @tools.asyncOpt fn, err, []

exports.getUserForActivities = (activities, fn) =>
  return @tools.asyncParallel activities, (activity) =>
    return @db.users.findById activity.inviting, (err, user) =>
      if not err and user
        activity.inviting = user
        return @tools.asyncDone activities, =>
          return @tools.asyncOpt fn, null, null
      return @tools.asyncOpt fn, err, []

exports.setStatus = (aid, newStatus) =>
  @client.hset "activities:#{aid}", 'status', newStatus
