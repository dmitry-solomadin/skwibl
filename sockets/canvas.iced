db = require '../db'
tools = require '../tools'

exports.configure = (sio) ->
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

      socket.on 'disconnect', ->
        console.log "A socket with sessionId #{hs.sessionId} disconnected."
        socket.leave socket.project

      socket.on 'elementUpdate', (data, cb) ->
        socket.broadcast.to(socket.project).emit 'elementUpdate',
          id: id
          canvasId: data.canvasId
          element: data.element
        db.actions.update socket.project, id, 'element', data

      socket.on 'elementRemove', (elementId, cb) ->
        socket.broadcast.to(socket.project).emit 'elementRemove',
          id: id
          elementId: elementId
        db.actions.delete elementId

      socket.on 'commentUpdate', (data, cb) ->
        socket.broadcast.to(socket.project).emit 'commentUpdate',
          id: id
          canvasId: data.canvasId
          element: data.element
        db.actions.update socket.project, id, 'comment', data, (err, action) ->
          if action.newAction
            newNumber =
              elementId: data.element.elementId
              newNumber: action.number

            # broadcast new number to everyone including sender
            socket.emit 'commentNumberUpdate', newNumber
            socket.broadcast.to(socket.project).emit 'commentNumberUpdate', newNumber

      socket.on 'commentRemove', (elementId, cb) ->
        socket.broadcast.to(socket.project).emit 'commentRemove',
          id: id
          elementId: elementId
        db.actions.delete elementId

      socket.on 'commentText', (data, cb) ->
        console.log "comemnt text"
        socket.broadcast.to(socket.project).emit 'commentText',
          id: id
          element: data
        db.comments.add data

      socket.on 'markAsTodo', (elementId, cb) ->
        socket.broadcast.to(socket.project).emit 'markAsTodo',
          id: id
          elementId: elementId
        db.comments.markAsTodo elementId

      socket.on 'resolveTodo', (elementId, cb) ->
        socket.broadcast.to(socket.project).emit 'resolveTodo',
          id: id
          elementId: elementId
        db.comments.resolveTodo elementId

      socket.on 'reopenTodo', (elementId, cb) ->
        socket.broadcast.to(socket.project).emit 'reopenTodo',
          id: id
          elementId: elementId
        db.comments.reopenTodo elementId

      socket.on 'updateCommentText', (data, cb) ->
        return unless `(data.owner == id)`

        socket.broadcast.to(socket.project).emit 'updateCommentText',
          id: id
          elementId: data.elementId
          text: data.text
        db.comments.update data.elementId, data.text

      socket.on 'eraseCanvas', (data, cb) ->
        socket.broadcast.to(socket.project).emit 'eraseCanvas',
          id: id
        db.canvases.clear data.canvasId

      socket.on 'changeCanvasName', (data, cb) ->
        socket.broadcast.to(socket.project).emit 'changeCanvasName',
          id: id
          name: data.name
        db.canvases.setProperties data.canvasId, name: data.name

      socket.on 'removeCanvas', (data, cb) ->
        socket.broadcast.to(socket.project).emit 'removeCanvas',
          id: id
          canvasId: data.canvasId
        db.canvases.delete data.canvasId

      socket.on 'fileAdded', (data, cb) ->
        socket.broadcast.to(socket.project).emit "fileAdded",
          id: id
          canvasData: data

      socket.on 'canvasAdded', (data, cb) ->
        socket.broadcast.to(socket.project).emit "canvasAdded",
          id: id
          canvasData: data

      socket.on 'initializeFirstCanvas', (data, cb) ->
        socket.broadcast.to(socket.project).emit "initializeFirstCanvas",
          id: id

      socket.on 'switchCanvas', (msg, cb) ->
        socket.broadcast.to(socket.project).emit 'switchCanvas',
          id: id
          canvasId: msg

      socket.on 'removeCommentText', (elementId, cb) ->
        socket.broadcast.to(socket.project).emit 'removeCommentText',
          id: id
          elementId: elementId
        db.comments.remove elementId

      socket.on 'userMouseDown', (data, cb) ->
        socket.broadcast.to(socket.project).emit 'userMouseDown',
          id: id
          x: data.x
          y: data.y
