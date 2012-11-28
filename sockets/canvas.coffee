
db = require '../db'
tools = require '../tools'

exports.configure = (sio) ->

  sendInitData = (project, socket) ->
    # get canvas saved elements
    console.log 'TODO'

  canvas = sio.of '/canvas'

  canvas.on 'connection', (socket) ->

    hs = socket.handshake
    id = hs.user.id

    db.projects.current id, (err, project) ->
      if err or not project
        console.log err, project
        return socket.disconnect()

      socket.join project
      socket.project = project

      sendInitData project, socket

      socket.on 'disconnect', ->
        console.log "A socket with sessionId #{hs.sessionId} disconnected."
        socket.leave socket.project

      socket.on 'elementUpdate', (data, cb) ->
        socket.broadcast.to(socket.project).emit 'elementUpdate',
          id: id
          canvasId: data.canvasId
          element: data.element
        db.actions.update socket.project, id, 'element', data

      socket.on 'elementRemove', (data, cb) ->
        console.log 'elremove'
        console.log data
        socket.broadcast.to(socket.project).emit 'elementRemove',
          id: id
          canvasId: data.canvasId
          elementId: data.elementId
        db.actions.remove data.elementId

      socket.on 'commentUpdate', (data, cb) ->
        console.log 'coupdate'
        console.log data
        data.comment = true
        socket.broadcast.to(socket.project).emit 'commentUpdate',
          id: id
          canvasId: data.canvasId
          element: data.element
        db.actions.update socket.project, id, 'element', data

      socket.on 'commentRemove', (data, cb) ->
        console.log 'cormove'
        console.log data
        socket.broadcast.to(socket.project).emit 'commentRemove',
          id: id
          canvasId: data.canvasId
          elementId: data.elementId
        db.actions.remove data.elementId

      socket.on 'commentText', (data, cb) ->
        console.log 'cotext'
        console.log data
        socket.broadcast.to(socket.project).emit 'commentText',
          id: id
          canvasId: data.canvasId
          element: data.element
        db.actions.updateComment data

      socket.on 'eraseCanvas', (data, cb) ->
        console.log 'erasecanv'
        console.log data
        socket.broadcast.to(socket.project).emit 'eraseCanvas',
          id: id
          canvasId: data.cancasId

      socket.on 'fileAdded', (data, cb) ->
        socket.broadcast.to(socket.project).emit "fileAdded",
          id: id
          canvasId: data.canvasId
          fileId: data.fileId

      socket.on 'switchCanvas', (msg, cb) ->
        socket.broadcast.to(socket.project).emit 'switchCanvas',
          id: id
          canvasId: msg
