fs = require 'fs'

exports.index = (uid, fn) =>
  @client.zrevrange "users:#{uid}:projects", 0, -1, (err, array) =>
    projects = []
    if not err and array and array.length
      return @tools.asyncParallel array, (pid) =>
        @db.projects.getData pid, (err, project) =>
          projects.push project if not err and project
          return @tools.asyncDone array, =>
            return @tools.asyncOpt fn, null, projects
    return @tools.asyncOpt fn, err, projects

exports.getData = (pid, fn) =>
  #TODO use async to simplify this function
  @client.hgetall "projects:#{pid}", (err, project) =>
    if not err and project
      return @db.projects.getUsers pid, (err, users) =>
        project.users = users
        return @db.projects.getUnconfirmedUsers pid, (err, unconfirmedUsers) =>
          project.unconfirmedUsers = unconfirmedUsers
          return @db.canvases.index pid, (err, canvases) =>
            project.canvases = canvases
            return @db.texts.getProjectTodos pid, 3, (err, todos) =>
              project.todos = todos
              return @db.texts.getProjectTodosCount pid, (err, todos) =>
                project.todosCount = todos
                return @tools.asyncOpt fn, err, project
    return @tools.asyncOpt fn, err, null

exports.findById = (pid, fn) =>
  @client.hgetall "projects:#{pid}", (err, project) =>
    @tools.asyncOpt fn, err, project

exports.getFiles = (pid, fn) =>
  @client.smembers "projects:#{pid}:files", (err, fileIds) =>
    if not err and fileIds and fileIds.length
      files = []
      return @tools.asyncParallel fileIds, (fid) =>
        @db.files.findById fid, (err, file) =>
          files.push file
          return @tools.asyncDone fileIds, =>
            @tools.asyncOpt fn, null, files
    return @tools.asyncOpt fn, err, []

# list of users that confirmed invitations
exports.getUsers = (pid, fn) =>
  @client.smembers "projects:#{pid}:users", (err, array) =>
    if not err and array and array.length
      users = []
      return @tools.asyncParallel array, (uid) =>
        @db.contacts.getInfo uid, (err, user) =>
          users.push user
          return @tools.asyncDone array, =>
            return @tools.asyncOpt fn, null, users
    return @tools.asyncOpt fn, err, []

# list of users that are not confirmed invitations
exports.getUnconfirmedUsers = (pid, fn) =>
  @client.zrange "projects:#{pid}:unconfirmed", 0, -1, 'WITHSCORES', (err, array) =>
    if not err and array and array.length
      users = []
      return @tools.asyncParallel array, (uid, i) =>
        if i % 2
          @db.contacts.getInfo uid, (err, user) =>
            users.push user
        return @tools.asyncDone array, =>
          return @tools.asyncOpt fn, null, users
    return @tools.asyncOpt fn, err, []

exports.add = (uid, name, fn) =>
  @client.incr 'projects:next', (err, val) =>
    if not err
      project = {}
      project.id = val
      project.name = name
      project.owner = uid
      project.createdAt = Date.now()
      project.status = 'new'
      @client.hmset "projects:#{val}", project, @tools.logError
      @client.sadd "projects:#{val}:users", uid
      @client.zadd "users:#{uid}:projects",  project.createdAt, val
      return @db.canvases.add val, null, null, (err, canvas) =>
        return @tools.asyncOpt(fn, err, project)
    return @tools.asyncOpt fn, err, null

exports.deleteCanvases = (pid, fn) =>
  @client.lrange "projects:#{pid}:canvases", 0, -1, (err, array) =>
    @client.del "projects:#{pid}:canvases" unless err
    if not err and array and array.length
      return @tools.asyncParallel array, (cid) =>
        @db.canvases.delete cid
        return @tools.asyncDone array, =>
          return @tools.asyncOpt fn, null, pid
    return @tools.asyncOpt fn, err, pid

exports.deleteUsers = (pid, fn) =>
  @client.smembers "projects:#{pid}:users", (err, array) =>
    if not err and array and array.length
      @db.contacts.deleteContacts pid, array, 0, fn
    @client.del "projects:#{pid}:users"
    return @tools.asyncOpt fn, err, pid

exports.deleteMessages = (pid, fn) =>
  @client.lrange "projects:#{pid}:messages", 0, -1, (err, array) =>
    @client.del "projects:#{pid}:messages" unless err
    if not err and array and array.length
      return @tools.asyncParallel array, (mid) =>
      @client.del @db.messages.delete mid
      return @tools.asyncDone array, =>
        return @tools.asyncOpt fn, null, pid
    return @tools.asyncOpt fn, err, pid

exports.deleteInvitations = (pid, fn) =>
  @client.zrange "projects:#{pid}:unconfirmed", 0, -1, (err, array) =>
    @client.del "projects:#{pid}:unconfirmed" unless err
    if not err and array and array.length
      return @tools.asyncParallel array, (aid) =>
        @db.activities.delete aid
        return @tools.asyncDone array, =>
          return @tools.asyncOpt fn, err, pid
    return @tools.asyncOpt fn, err, pid

exports.delete = (pid, fn) =>
  @db.projects.deleteCanvases pid
  @db.projects.deleteUsers pid
  @db.projects.deleteMessages pid
  @db.projects.deleteInvitations pid
  @client.del "projects:#{pid}", fn

exports.setProperties = (pid, properties, fn) =>
  purifiedProp = @tools.purify properties
  return @client.hmset "projects:#{pid}", purifiedProp, fn

exports.invite = (pid, id, user, fn) =>
  # Do not invite yourself
  if user.id is id
    return @tools.asyncOptError fn, 'Cannot invite yourself'
  if user.status is 'deleted'
    return @tools.asyncOptError fn, 'Cannot invite deleted user'
  # Check if user exists
  return @client.exists "users:#{user.id}", (err, val) =>
    if not err and val
      # check if user is already invited
      return @client.zrangebyscore "projects:#{pid}:unconfirmed", user.id, user.id, (err, array) =>
        if not err and array and not array.length
          return @db.activities.add pid, user.id, 'projectInvite', id, {}, (err, activity) =>
            if not err and activity
              @client.zadd "projects:#{pid}:unconfirmed", user.id, activity.id
            return @tools.asyncOpt fn, err, user
        return @tools.asyncOptError fn, "This user has already been invited to project.", null
    if not val
      return @tools.asyncOpt fn, new Error 'Record not found'
    return @tools.asyncOpt fn, err, null

exports.inviteSocial = (pid, provider, providerId, fn) =>
  #TODO
  console.log 'invite social'

exports.inviteEmail = (pid, id, email, fn) =>
  unless email and @tools.isEmail email
    return @tools.asyncOptError fn, "Please, enter an email."
  @db.users.findByEmail email, (err, user) =>
    return @tools.asyncOpt fn, err if err
    if not user
      hash = @tools.hash email
      password = @tools.genPass()
      return @db.users.add
        hash: hash
        password: password
        status: 'unconfirmed'
        provider: 'local'
      , null, [value: email], (err, user) =>
        return @tools.asyncOpt fn err, null if err
        return @tools.asyncOpt fn new Error 'Can not create user.', null if not user
        @db.projects.invite pid, id, user
        return @db.users.findById id, (err, contact) =>
          return @smtp.regPropose contact, user, hash, fn
    return @db.projects.invite pid, id, user, fn

exports.inviteLink = (pid, fn) =>
  #TODO
  console.log 'invite link'

exports.accept = (pid, aid, uid, fn) =>
  @db.contacts.add pid, uid
  # Add the user to the project
  @client.zrem "projects:#{pid}:unconfirmed", aid
  @client.sadd "projects:#{pid}:users", uid
  # Add the project to the user
  @client.zadd "users:#{uid}:projects", Date.now(), pid
  @db.activities.addForAllInProject pid, 'projectJoin', uid, [uid], {}
  return fn null, pid

exports.decline = (pid, aid, fn) =>
  @client.zrem "projects:#{pid}:unconfirmed", aid, fn

# remove user from project.
exports.remove = (pid, uid, isLeave, fn) =>
  # Remove project from user projects
  @client.zrem "users:#{uid}:projects", pid
  # Get project members
  @client.smembers "projects:#{pid}:users", (err, array) =>
    if not err and array and array.length
      @db.contacts.recalculate uid, array, pid
      return @tools.asyncParallel array, (cid) =>
        # Recalculate member contacts
        @db.contacts.recalculate cid, [uid], pid
        return @tools.asyncDone array, =>
          # Remove user from project members
          @client.srem "projects:#{pid}:users", uid
          if isLeave
            return @db.activities.addForAllInProject pid, 'projectLeave', uid, [uid], {}, (err) =>
              return @tools.asyncOpt fn, null
          return @tools.asyncOpt fn, null
    return @tools.asyncOpt fn, err

exports.confirm = (aid, uid, answer, fn) =>
  return @client.hget "activities:#{aid}", 'project', (err, val) =>
    if not err and val
      if answer is 'true'
        @client.hset "activities:#{aid}", 'status', 'accepted'
        return @db.projects.accept val, aid, uid, fn
      @client.hset "activities:#{aid}", 'status', 'declined'
      return @db.projects.decline val, aid, fn
    return @tools.asyncOpt fn, err, val

exports.set = (id, pid, fn) =>
  @client.hset "projects:#{pid}", 'updatedAt', Date.now()
  @client.set "users:#{id}:current", pid, fn

exports.current = (id, fn) =>
  @client.get "users:#{id}:current", fn

exports.createDemo = (uid, fn) ->
  @db.projects.add uid, 'Demo Project', (err, project) =>
    dir = "#{@cfg.UPLOADS}/#{project.id}"
    fs.mkdir dir, @cfg.DIRECTORY_PERMISSION, (err) =>
      fs.mkdir "#{dir}/video", @cfg.DIRECTORY_PERMISSION
      fs.mkdir "#{dir}/image", @cfg.DIRECTORY_PERMISSION, (err) =>
        #TODO use symlink with realpath instead
        fs.createReadStream('./uploads/demo/image/Skibwl_room_9.png').pipe(fs.createWriteStream("./uploads/#{project.id}/image/Skibwl_room_9.png"))
        fs.createReadStream('./uploads/demo/image/Skibwl_room_7_2.png').pipe(fs.createWriteStream("./uploads/#{project.id}/image/Skibwl_room_7_2.png"))
        @client.lrange "projects:#{project.id}:canvases", 0 ,-1, (err, canvases) =>
          @db.files.add uid, canvases[0], project.id, 'Skibwl_room_9.png', 'image/png', 680, 300
        @db.canvases.add project.id, null, null, (err, canvas) =>
          @db.files.add uid, canvas.id, project.id, 'Skibwl_room_7_2.png', 'image/png', 680, 300
        for size of @cfg.PROJECT_THUMB_SIZE
          fs.mkdir "#{dir}/image/#{size}", @cfg.DIRECTORY_PERMISSION
          fs.createReadStream('./uploads/demo/image/lsmall/Skibwl_room_7_2.png').pipe(fs.createWriteStream("./uploads/#{project.id}/image/lsmall/Skibwl_room_7_2.png"))
          fs.createReadStream('./uploads/demo/image/rsmall/Skibwl_room_7_2.png').pipe(fs.createWriteStream("./uploads/#{project.id}/image/rsmall/Skibwl_room_7_2.png"))
          fs.createReadStream('./uploads/demo/image/tiny/Skibwl_room_7_2.png').pipe(fs.createWriteStream("./uploads/#{project.id}/image/tiny/Skibwl_room_7_2.png"))
          fs.createReadStream('./uploads/demo/image/lsmall/Skibwl_room_9.png').pipe(fs.createWriteStream("./uploads/#{project.id}/image/lsmall/Skibwl_room_9.png"))
          fs.createReadStream('./uploads/demo/image/rsmall/Skibwl_room_9.png').pipe(fs.createWriteStream("./uploads/#{project.id}/image/rsmall/Skibwl_room_9.png"))
          fs.createReadStream('./uploads/demo/image/tiny/Skibwl_room_9.png').pipe(fs.createWriteStream("./uploads/#{project.id}/image/tiny/Skibwl_room_9.png"))
