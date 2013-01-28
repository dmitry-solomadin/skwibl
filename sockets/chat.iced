
db = require '../db'
tools = require '../tools'

exports.configure = (sio) ->

  sendInitData = (pid, socket) ->
    clients = sio.sockets.clients "chat/#{pid}"

    onlineUsers = []
    for client in clients
      ssid = client.id
      hsn = client.manager.handshaken
      id = hsn[ssid].user.id
      onlineUsers.push id

    socket.json.emit 'onlineUsers', onlineUsers

  chat = sio.of '/chat'

  chat.on 'connection', (socket) ->

    hs = socket.handshake
    id = hs.user.id

    db.projects.current id, (err, pid) ->
      if err or not pid
        return socket.disconnect()

      socket.join pid
      socket.project = pid

      sendInitData pid, socket

      socket.broadcast.to(pid).emit 'enter',
        id: id
        displayName: hs.user.displayName
        picture: hs.user.picutre

      socket.on 'disconnect', ->
        socket.leave socket.project
        socket.broadcast.to(socket.project).emit 'exit', id

      socket.on 'userRemoved', (uid) ->
        socket.broadcast.to(socket.project).emit 'userRemoved', uid

      socket.on 'message', (data) ->
#         console.log data
        socket.broadcast.to(socket.project).emit 'message',
          id: id
          message: data
        db.messages.update socket.project, id, data
