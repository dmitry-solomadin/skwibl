
db = require '../db'
tools = require '../tools'

exports.configure = (sio) ->

  sendInitData = (pid, socket) ->
    clients = sio.sockets.clients "chat/#{pid}"

    db.projects.getUsers pid, (err, users) ->
      if not err and users
        loggedIn = tools.getUsers clients, pid
        for user in users
          if loggedIn.indexOf user.id isnt -1
            user.status = 'online'
        socket.json.emit 'users', users

    db.actions.get pid, 'chat', (err, actions) ->
      if actions.length isnt 0
        socket.emit 'messages', actions

  chat = sio.of '/chat'

  chat.on 'connection', (socket) ->

    hs = socket.handshake
    id = hs.user.id

    db.projects.current id, (err, pid) ->
      if err or not pid
        console.log err, pid
        return socket.disconnect()

      socket.join pid
      socket.project = pid

      sendInitData pid, socket

      socket.broadcast.to(pid).emit 'enter', id

      socket.on 'disconnect', ->
        console.log "A socket with sessionId ${hs.sessionId} disconnected."
        socket.leave socket.project
        socket.broadcast.to(socket.project).emit 'exit', id

      socket.on 'message', (msg, cb) ->
        socket.broadcast.to(socket.project).emit 'message',
          id: id
          message: msg
        db.actions.update socket.project, id, 'chat', msg

#       socket.on 'switch', (project) ->
#         # assume that project is valid user project
#         socket.leave socket.project
#         socket.broadcast.to(socket.project).emit 'exit', id
#         socket.project = project
#         socket.join project
#         db.projects.set id, project
#         console.log 'switch', project
#         socket.broadcast.to(project).emit 'enter', id
#         sendInitData project, socket
