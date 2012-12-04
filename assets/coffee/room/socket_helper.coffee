$ ->
  class RoomSocketHelper

    constructor: ->
      socket = io.connect('/canvas', window.copt)
      App.room.socket = socket

      socket.on 'elementUpdate', (data) => @addOrUpdateElement(data.element)
      socket.on 'elementRemove', (data) => @socketRemoveElement(data.elementId)
      socket.on 'commentUpdate', (data) => @addOrUpdateComment(data.element)
      socket.on 'commentRemove', (data) => @socketRemoveComment(data.elementId)
      socket.on 'commentText', (data) => @addCommentText(data.element)
      socket.on 'fileAdded', (data) => room.canvas.handleUpload(data.canvasId, data.fileId, false)
      socket.on 'removeCommentText', (data) => room.comments.removeText(data.elementId, false)
      socket.on 'updateCommentText', (data) => room.comments.doEditText(data.elementId, data.text, false)
      socket.on 'switchCanvas', (data) =>
        room.canvas.selectThumb(room.canvas.findThumbByCanvasId(data.canvasId), false)

      socket.on 'eraseCanvas', =>
        room.canvas.erase()
        room.redrawWithThumb()

    addCommentText: (element) ->
      foundComment = room.helper.findByElementId element.commentId
      room.comments.addCommentText foundComment.commentMin, element

    addOrUpdateComment: (data) ->
      updateComment = (comment, updatedComment) =>
        comment.commentMin.css(left: updatedComment.min.x, top: updatedComment.min.y)
        comment.commentMin[0].$maximized.css(left: updatedComment.max.x, top: updatedComment.max.y)
        room.comments.redrawArrow(comment.commentMin)

      foundComment = room.helper.findByElementId(data.elementId)
      if foundComment then updateComment(foundComment, data) else @createCommentFromData(data)

      room.redrawWithThumb()

    createCommentFromData: (comment) ->
      if comment.rect
        rect = new Path.RoundRectangle(comment.rect.x, comment.rect.y, comment.rect.w, comment.rect.h, 8, 8)
        room.items.create(rect, room.comments.COMMENT_STYLE)

      commentMin = room.comments.create(comment.min.x, comment.min.y, rect, comment.max)
      commentMin.elementId = comment.elementId

      if rect
        rect.commentMin = commentMin
        rect.eligible = false
        room.history.add(rect)
      else
        room.history.add({actionType: "comment", commentMin: commentMin, eligible: false})

      commentMin

    socketRemoveElement: (elementId) ->
      room.helper.findByElementId(elementId).remove()
      room.items.unselectIfSelected(elementId)
      room.redrawWithThumb()

    socketRemoveComment: (elementId) ->
      element = room.helper.findByElementId(elementId)

      commentMin = element.commentMin
      commentMin[0].$maximized.remove()
      commentMin[0].arrow.remove()
      commentMin[0].rect.remove() if commentMin[0].rect
      commentMin.remove()

      room.items.unselectIfSelected(elementId)
      room.redrawWithThumb()

    addOrUpdateElement: (element) ->
      foundPath = room.helper.findByElementId(element.elementId)
      if foundPath
        room.items.unselectIfSelected(foundPath.elementId)
        foundPath.removeSegments()
        $(element.segments).each ->
          foundPath.addSegment(room.socketHelper.createSegment(@.x, @.y, @.ix, @.iy, @.ox, @.oy))

        if foundPath.commentMin
          room.comments.redrawArrow(foundPath.commentMin)
      else
        path = @createElementFromData(element)

        room.items.create path,
          color: element.strokeColor
          width: element.strokeWidth
          opacity: element.opacity

        path.eligible = false
        room.history.add(path)

      room.redrawWithThumb()

    createSegment: (x, y, ix, iy, ox, oy) ->
      handleIn = new Point(ix, iy)
      handleOut = new Point(ox, oy)
      firstPoint = new Point(x, y)

      return new Segment(firstPoint, handleIn, handleOut)

    createElementFromData: (data) ->
      path = new Path()
      $(data.segments).each ->
        path.addSegment(room.socketHelper.createSegment(@.x, @.y, @.ix, @.iy, @.ox, @.oy))
      path.closed = data.closed
      path.elementId = data.elementId

      path

    prepareElementToSend: (elementToSend) ->
      data =
        canvasId: room.canvas.getSelectedCanvasId()
        element:
          elementId: if elementToSend.commentMin then elementToSend.commentMin.elementId else elementToSend.elementId
          canvasId: room.canvas.getSelectedCanvasId()
          segments: []
          closed: elementToSend.closed
          strokeColor: elementToSend.strokeColor.toCssString()
          strokeWidth: elementToSend.strokeWidth
          opacity: elementToSend.opacity

      for segment in elementToSend.segments
        data.element.segments.push
          x: segment.point.x
          y: segment.point.y
          ix: segment.handleIn.x
          iy: segment.handleIn.y
          ox: segment.handleOut.x
          oy: segment.handleOut.y

      data

    prepareCommentToSend: (commentMin) ->
      data =
        canvasId: room.canvas.getSelectedCanvasId()
        element:
          elementId: commentMin.elementId
          min:
            x: commentMin.position().left
            y: commentMin.position().top

      commentMax = commentMin[0].$maximized[0]
      if commentMax
        data.element.max =
          x: $(commentMax).position().left
          y: $(commentMax).position().top

      commentRect = commentMin[0].rect
      if commentRect
        data.element.rect =
          x: commentRect.bounds.x
          y: commentRect.bounds.y
          w: commentRect.bounds.width
          h: commentRect.bounds.height

      data

  App.room.socketHelper = new RoomSocketHelper