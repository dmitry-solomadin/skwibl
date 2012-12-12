$ ->
  return unless currentPage "projects/show"

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
      socket.on 'markAsTodo', (data) => room.comments.markAsTodo(data.elementId, false)
      socket.on 'resolveTodo', (data) => room.comments.resolveTodo(data.elementId, false)
      socket.on 'reopenTodo', (data) => room.comments.reopenTodo(data.elementId, false)
      socket.on 'switchCanvas', (data) =>
        room.canvas.selectThumb(room.canvas.findThumbByCanvasId(data.canvasId), false)
      socket.on 'eraseCanvas', => room.canvas.clear false, false
      socket.on 'removeCanvas', => room.canvas.clear true, false

    addCommentText: (element) ->
      foundComment = room.helper.findByElementId element.commentId
      room.comments.addCommentText foundComment.commentMin, element

    addOrUpdateComment: (data) ->
      # adjust position if canvas was panned
      if opts.pandx isnt 0 or opts.pandy isnt 0
        data.min.x = data.min.x + opts.pandx
        data.min.y = data.min.y + opts.pandy
        data.max.x = data.max.x + opts.pandx
        data.max.y = data.max.y + opts.pandy

        if data.rect
          data.rect.x = data.rect.x + opts.pandx
          data.rect.y = data.rect.y + opts.pandy

      # adjust position if canvas was sacled
      minPos = room.applyReverseCurrentScale(new Point(data.min.x, data.min.y))
      data.min.x = minPos.x
      data.min.y = minPos.y
      maxPos = room.applyReverseCurrentScale(new Point(data.max.x, data.max.y))
      data.max.x = maxPos.x
      data.max.y = maxPos.y

      updateComment = (comment, updatedComment) =>
        comment.commentMin.css(left: minPos.x, top: minPos.y)
        comment.commentMin[0].$maximized.css(left: maxPos.x, top: maxPos.y)

        if comment.commentMin[0].rect and updatedComment.rect
          comment.commentMin[0].rect.position = new Point(updatedComment.rect.x + (updatedComment.rect.w / 2),
            updatedComment.rect.y + (updatedComment.rect.h / 2));

        room.comments.redrawArrow(comment.commentMin)

      foundComment = room.helper.findByElementId(data.elementId)
      if foundComment
        updateComment(foundComment, data)
      else
        commentMin = @createCommentFromData(data)

        for text in data.texts
          room.comments.addCommentText commentMin, text

      room.redrawWithThumb()

    createCommentFromData: (comment) ->
      if comment.rect
        rect = new Path.RoundRectangle(comment.rect.x, comment.rect.y, comment.rect.w, comment.rect.h, 8, 8)
        room.items.create rect, color: comment.color

      commentMin = room.comments.create(comment.min.x, comment.min.y, rect, comment.max, comment.color)
      commentMin.elementId = comment.elementId

      if rect
        rect.commentMin = commentMin
        rect.eligible = false
        room.history.add(rect)
      else
        room.history.add({actionType: "comment", commentMin: commentMin, eligible: false})

      commentMin

    socketRemoveElement: (elementId) ->
      room.helper.findAndRemoveByElementId(elementId).remove()
      room.items.unselectIfSelected(elementId)
      room.redrawWithThumb()

    socketRemoveComment: (elementId) ->
      element = room.helper.findAndRemoveByElementId(elementId)

      commentMin = element.commentMin
      commentMin[0].$maximized.remove()
      commentMin[0].arrow.remove()
      commentMin[0].rect.remove() if commentMin[0].rect
      commentMin.remove()

      room.items.unselectIfSelected(elementId)
      room.redrawWithThumb()

    addOrUpdateElement: (element) ->
      if opts.pandx isnt 0 or opts.pandy isnt 0
        for segment in element.segments
          segment.x = segment.x + opts.pandx
          segment.y = segment.y + opts.pandy

      foundPath = room.helper.findByElementId(element.elementId)
      if foundPath
        room.items.unselectIfSelected(foundPath.elementId)
        foundPath.removeSegments()
        $(element.segments).each ->
          foundPath.addSegment(room.socketHelper.createSegment(@.x, @.y, @.ix, @.iy, @.ox, @.oy))

        foundPath.opacity = 1

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

      if data.isArrow
        room.items.drawArrow(path)
      else
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
          isArrow: if elementToSend.arrow then true else false

      segments = if elementToSend.arrow then elementToSend.arrow.segments else elementToSend.segments
      for segment in segments
        data.element.segments.push
          x: segment.point.x - opts.pandx
          y: segment.point.y - opts.pandy
          ix: segment.handleIn.x
          iy: segment.handleIn.y
          ox: segment.handleOut.x
          oy: segment.handleOut.y

      data

    prepareCommentToSend: (commentMin) ->
      # apply current scale before sending coordinates
      commentMax = commentMin[0].$maximized[0]
      commentMinPosition = new Point(commentMin.position().left, commentMin.position().top)
      commentMaxPosition = new Point($(commentMax).position().left, $(commentMax).position().top)
      commentMinPosition = room.applyCurrentScale commentMinPosition
      commentMaxPosition = room.applyCurrentScale commentMaxPosition

      # comment may already contain text if we are restoring deleted comment via 'undo'
      data =
        canvasId: room.canvas.getSelectedCanvasId()
        element:
          elementId: commentMin.elementId
          color: commentMin.data("color")
          texts: @prepareCommentTextsToSend commentMin
          min:
            x: commentMinPosition.x - opts.pandx
            y: commentMinPosition.y - opts.pandy

      if commentMax
        data.element.max =
          x: commentMaxPosition.x - opts.pandx
          y: commentMaxPosition.y - opts.pandy

      commentRect = commentMin[0].rect
      if commentRect
        data.element.rect =
          x: commentRect.bounds.x - opts.pandx
          y: commentRect.bounds.y - opts.pandy
          w: commentRect.bounds.width
          h: commentRect.bounds.height

      data

    prepareCommentTextsToSend: (commentMin) ->
      texts = []
      for commentText in commentMin[0].$maximized.find(".comment-text")
        texts.push @prepareCommentTextToSend(commentText)
      texts

    prepareCommentTextToSend: (commentText) ->
      elementId: $(commentText).data("element-id")
      commentId: $(commentText).data("comment-id")
      owner: $(commentText).data("owner")
      text: $(commentText).find(".the-comment-text").html()

  App.room.socketHelper = new RoomSocketHelper