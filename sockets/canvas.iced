db = require '../db'
tools = require '../tools'

exports.configure = (sio) ->
  canvas = sio.of '/canvas'

  canvas.on 'connection', (socket) ->
    hs = socket.handshake
    id = hs.user.id

    db.projects.current id, (err, project) ->
      if err or not project
#         console.log err, project
        return socket.disconnect()

      socket.join project
      socket.project = project

      socket.on 'disconnect', ->
#         console.log "A socket with sessionId #{hs.sessionId} disconnected."
        socket.leave socket.project

      socket.on 'elementUpdate', (data) ->
        db.canvases.getProject data.canvasId, (err, project) ->
          if project is socket.project
            if data.action is 'create'
              #TODO move this to function
              socket.broadcast.to(socket.project).emit 'elementUpdate',
                id: id
                canvasId: data.canvasId
                element: data.element
              db.elements.update socket.project, id, data
            else
              db.elements.getCanvas data.element.elementId, (err, canvasId) ->
                if canvasId is "#{data.canvasId}"
                  socket.broadcast.to(socket.project).emit 'elementUpdate',
                    id: id
                    canvasId: data.canvasId
                    element: data.element
                  db.elements.update socket.project, id, data

      socket.on 'elementRemove', (data) ->
        db.canvases.getProject data.canvasId, (err, project) ->
          if project is socket.project
            db.elements.getCanvas data.elementId, (err, canvasId) ->
              if canvasId is "#{data.canvasId}"
                socket.broadcast.to(socket.project).emit 'elementRemove',
                  id: id
                  elementId: data.elementId
                db.elements.delete data.elementId

      socket.on 'commentUpdate', (data) ->
#         console.log data
        db.canvases.getProject data.canvasId, (err, project) ->
          if project is socket.project
            if data.action is 'create'
              #TODO move this to function
              socket.broadcast.to(socket.project).emit 'commentUpdate',
                id: id
                canvasId: data.canvasId
                element: data.element
              number = "#{data.number}".trim()
              db.comments.update socket.project, id, data, (err, action) ->
                if not err and data.action is 'create'
                  newNumber =
                    elementId: data.element.elementId
                    newNumber: action.number
                  # broadcast new number to everyone including sender
                  socket.emit 'commentNumberUpdate', newNumber
                  socket.broadcast.to(socket.project).emit 'commentNumberUpdate', newNumber
            else
              db.comments.getCanvas data.element.elementId, (err, canvasId) ->
                if canvasId is "#{data.canvasId}"
                  socket.broadcast.to(socket.project).emit 'commentUpdate',
                    id: id
                    canvasId: data.canvasId
                    element: data.element
                  number = "#{data.number}".trim()
                  db.comments.update socket.project, id, data, (err, action) ->
                    if not err and data.action is 'create'
                      newNumber =
                        elementId: data.element.elementId
                        newNumber: action.number
                      # broadcast new number to everyone including sender
                      socket.emit 'commentNumberUpdate', newNumber
                      socket.broadcast.to(socket.project).emit 'commentNumberUpdate', newNumber

      socket.on 'commentRemove', (data) ->
        db.canvases.getProject data.canvasId, (err, project) ->
          if project is socket.project
            db.comments.getCanvas data.elementId, (err, canvasId) ->
              if canvasId is "#{data.canvasId}"
                socket.broadcast.to(socket.project).emit 'commentRemove',
                  id: id
                  elementId: data.elementId
                db.comments.delete data.elementId

      socket.on 'commentText', (data) ->
#         console.log 'commentText'
#         console.log data
        socket.broadcast.to(socket.project).emit 'commentText',
          id: id
          element: data
        db.texts.add data, true

      socket.on 'markAsTodo', (elementId) ->
#         console.log 'markAsTodo'
        socket.broadcast.to(socket.project).emit 'markAsTodo',
          id: id
          elementId: elementId
        db.texts.markAsTodo elementId

      socket.on 'resolveTodo', (elementId) ->
#         console.log 'resolveTodo'
        socket.broadcast.to(socket.project).emit 'resolveTodo',
          id: id
          elementId: elementId
        db.texts.resolveTodo elementId

      socket.on 'reopenTodo', (elementId) ->
#         console.log 'reopenTodo'
        socket.broadcast.to(socket.project).emit 'reopenTodo',
          id: id
          elementId: elementId
        db.texts.reopenTodo elementId

      socket.on 'updateCommentText', (data) ->
#         console.log 'updateCommentText'
#         console.log data
        return unless "#{data.owner}" is "#{id}"
        socket.broadcast.to(socket.project).emit 'updateCommentText',
          id: id
          elementId: data.elementId
          text: data.text
        db.texts.update data.elementId, data.text

      socket.on 'eraseCanvas', (data) ->
        db.canvases.getProject data.canvasId, (err, project) ->
          if project is socket.project
            socket.broadcast.to(socket.project).emit 'eraseCanvas',
              id: id
            db.canvases.clear data.canvasId

      socket.on 'changeCanvasName', (data) ->
        db.canvases.getProject data.canvasId, (err, project) ->
          if project is socket.project
            socket.broadcast.to(socket.project).emit 'changeCanvasName',
              id: id
              name: data.name
            db.canvases.setProperties data.canvasId, name: data.name

      socket.on 'removeCanvas', (data) ->
#         console.log data
        db.canvases.getProject data.canvasId, (err, project) ->
          if project is socket.project
            socket.broadcast.to(project).emit 'removeCanvas',
              id: id
              canvasId: data.canvasId
            db.canvases.delete data.canvasId

      socket.on 'fileAdded', (data) ->
#         console.log 'fileAdded'
#         console.log data
        socket.broadcast.to(socket.project).emit "fileAdded",
          id: id
          canvasData: data

      socket.on 'canvasAdded', (data) ->
#         console.log 'canvasAdded'
#         console.log data
        socket.broadcast.to(socket.project).emit "canvasAdded",
          id: id
          canvasData: data

      socket.on 'initializeFirstCanvas', (canvasId) ->
#         console.log canvasId
        db.canvases.getProject canvasId, (err, project) ->
          if project is socket.project
#             socket.canvas = canvasId
            socket.broadcast.to(project).emit "initializeFirstCanvas",
              id: id

      socket.on 'switchCanvas', (canvasId) ->
#         console.log 'switchCanvas'
#         console.log canvasId
        db.canvases.getProject canvasId, (err, project) ->
          if project is socket.project
#             socket.canvas = canvasId
            socket.broadcast.to(socket.project).emit 'switchCanvas',
              id: id
              canvasId: canvasId

      socket.on 'removeCommentText', (elementId) ->
        socket.broadcast.to(socket.project).emit 'removeCommentText',
          id: id
          elementId: elementId
        db.texts.remove elementId

      socket.on 'userMouseDown', (data) ->
        socket.broadcast.to(socket.project).emit 'userMouseDown',
          id: id
          x: data.x
          y: data.y
