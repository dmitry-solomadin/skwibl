$ ->
  class RoomComments extends App.RoomComponent

    constructor: ->
      @SIDE_OFFSET = 15
      @CORNER_OFFSET = 18

      @COMMENT_RECTANGLE_ROUNDNESS = 8
      @COMMENT_STYLE = {width: "2", color: "#C2E1F5"}

    create: (x, y, rect, max) ->
      COMMENT_SHIFT_X = 75
      COMMENT_SHIFT_Y = -135

      if y < 100
        COMMENT_SHIFT_X = 75
        COMMENT_SHIFT_Y = 55

      commentMin = $("<div class=\"comment-minimized #{'hide' if rect}\">&nbsp;</div>")
      commentMin.css(left: x, top: y)

      commentMax = $("<div class='comment-maximized'></div>")
      max_x = if max then max.x else x + COMMENT_SHIFT_X
      max_y = if max then max.y else y + COMMENT_SHIFT_Y
      commentMax.css(left: max_x, top: max_y)
      commentHeader = $("<div class='comment-header'>" +
      "<div class='fr'><span class='comment-minimize'></span><span class='comment-remove'></span></div>" +
      "</div>")

      commentHeader.find(".comment-minimize").on "click", => @foldComment(commentMin)
      commentHeader.find(".comment-remove").on "click", => @removeComment(commentMin)
      commentMin.on "mousedown", => @unfoldComment(commentMin)

      commentMax.append(commentHeader)
      commentContent = $("<div class='comment-content'>" +
      "<textarea class='comment-reply' placeholder='Type a comment...'></textarea>" +
      "<input type='button' class='btn fr comment-send hide' value='Send'>" +
      "</div>")
      commentMax.append(commentContent)

      commentHeader[0].commentMin = commentMin
      commentHeader.drags
        onDrag: (dx, dy) =>
          commentMax.css(left: (commentMax.position().left + dx) + "px", top: (commentMax.position().top + dy) + "px")
          @redrawArrow(commentMin)
        onAfterDrag: =>
          @room().socket.emit("commentUpdate", @room().socketHelper.prepareCommentToSend(commentMin))

      commentMin.drags
        onDrag: (dx, dy) =>
          commentMin.css({left: (commentMin.position().left + dx) + "px", top: (commentMin.position().top + dy) + "px"})
          @redrawArrow(commentMin)
        onAfterDrag: =>
          @room().socket.emit("commentUpdate", @room().socketHelper.prepareCommentToSend(commentMin))

      $(document).on "click", (evt) =>
        for commentSendButton in $(".comment-send:visible")
          $(commentSendButton).hide()
          @redrawArrow(commentMin)

        $(evt.target).parent(".comment-content").find(".comment-send").show() if evt.target

      $(commentMax).find(".comment-send").on "click", =>
        commentTextarea = commentMax.find(".comment-reply")
        @addCommentText(commentMin, commentTextarea.val(), true)
        commentTextarea.val("")

      commentMin[0].$maximized = commentMax
      commentMin[0].rect = rect

      $("#room-content").prepend(commentMin)
      $("#room-content").prepend(commentMax)

      bp = @getArrowBindPoint(commentMin, commentMax.position().left + (commentMax.width() / 2),
      commentMax.position().top + (commentMax.height() / 2))
      zone = @getZone(commentMax.position().left, commentMax.position().top,
      bp.x, bp.y, commentMax.width(), commentMax.height())

      coords = @getArrowCoords(commentMin, zone)
      path = new Path()
      path.strokeColor = '#C2E1F5'
      path.strokeWidth = "2"
      path.fillColor = "#FCFCFC"
      path.add(new Point(coords.x0, coords.y0))
      path.add(new Point(coords.x1, coords.y1))
      path.add(new Point(coords.x2, coords.y2))
      path.closed = true
      paper.project.activeLayer.addChild(path)

      commentMin[0].arrow = path

      commentMin

    getZone: (left, top, x0, y0, w, h) ->
      c = @getCommentCoords(left, top, w, h)

      c.xtl = c.xtl / @opts().currentScale
      c.ytl = c.ytl / @opts().currentScale
      c.xtr = c.xtr / @opts().currentScale
      c.ytr = c.ytr / @opts().currentScale
      c.xbl = c.xbl / @opts().currentScale
      c.ybl = c.ybl / @opts().currentScale
      c.xbr = c.xbr / @opts().currentScale
      c.ybr = c.ybr / @opts().currentScale

      return 1 if x0 <= c.xtl and y0 <= c.ytl
      return 2 if x0 > c.xtl and x0 < c.xtr and y0 < c.ytl
      return 3 if x0 >= c.xtr and y0 <= c.ytr
      return 4 if x0 < c.xtl and y0 < c.ybl and y0 > c.ytl
      return 5 if x0 >= c.xtl and x0 <= c.xtr and y0 <= c.ybl and y0 >= c.ytl
      return 6 if x0 > c.xtr and y0 < c.ybr and y0 > c.ytr
      return 7 if x0 <= c.xbl and y0 >= c.ybl
      return 8 if x0 > c.xbl and x0 < c.xbr and y0 > c.ybl
      return 9 if x0 >= c.xbr and y0 >= c.ybr

    getCommentCoords: (left, top, width, height) ->
      xtl: left, ytl: top
      xtr: left + width, ytr: top
      xbl: left, ybl: top + height
      xbr: left + width, ybr: top + height

    getArrowPos: (zone, c, w, h) ->
      x1 = 0
      y1 = 0
      x2 = 0
      y2 = 0
      w2 = w / 2
      h2 = h / 2

      switch zone
        when 1 then do =>
          x1 = c.xtl
          y1 = c.ytl + @CORNER_OFFSET
          x2 = c.xtl + @CORNER_OFFSET
          y2 = c.ytl
        when 2 then do =>
          x2 = c.xtl + w2 + @SIDE_OFFSET
          y2 = c.ytl
          x1 = c.xtl + w2 - @SIDE_OFFSET
          y1 = c.ytl
        when 3 then do =>
          x1 = c.xtr - @CORNER_OFFSET
          y1 = c.ytr
          x2 = c.xtr
          y2 = c.ytr + @CORNER_OFFSET
        when 4 then do =>
          x1 = c.xtl
          y1 = c.ytl + h2 + @SIDE_OFFSET
          x2 = c.xtl
          y2 = c.ytl + h2 - @SIDE_OFFSET
        when 5 then do =>
        when 6 then do =>
          x1 = c.xtr
          y1 = c.ytr + h2 - @SIDE_OFFSET
          x2 = c.xtr
          y2 = c.ytr + h2 + @SIDE_OFFSET
        when 7 then do =>
          x1 = c.xbl + @CORNER_OFFSET
          y1 = c.ybl
          x2 = c.xbl
          y2 = c.ybl - @CORNER_OFFSET
        when 8 then do =>
          x1 = c.xbl + w2 + @SIDE_OFFSET
          y1 = c.ybl
          x2 = c.xbl + w2 - @SIDE_OFFSET
          y2 = c.ybl
        when 9 then do =>
          x1 = c.xbr
          y1 = c.ybr - @CORNER_OFFSET
          x2 = c.xbr - @CORNER_OFFSET
          y2 = c.ybr

      x1: x1, y1: y1, x2: x2, y2: y2

    getArrowCoords: ($commentMin, zone) ->
      commentMax = $commentMin[0].$maximized

      return null if zone == 5

      w = commentMax.width()
      h = commentMax.height()
      c = @getCommentCoords(commentMax.position().left, commentMax.position().top, w, h)

      bp = @getArrowBindPoint($commentMin, c.xtl + (w / 2), c.ytl + (h / 2))
      pos = @getArrowPos(zone, c, w, h)

      x0: bp.x, y0: bp.y, x1: pos.x1, y1: pos.y1, x2: pos.x2, y2: pos.y2

    getArrowBindPoint: ($commentMin, cmX, cmY) ->
      rect = $commentMin[0].rect

      if not rect
        return {x: $commentMin.position().left + ($commentMin.width() / 2),
        y: $commentMin.position().top + ($commentMin.height() / 2)}
      else
        rect.xtl = rect.bounds.x
        rect.ytl = rect.bounds.y
        rect.xtr = rect.bounds.x + rect.bounds.width
        rect.ytr = rect.bounds.y
        rect.xbl = rect.bounds.x
        rect.ybl = rect.bounds.y + rect.bounds.height
        rect.xbr = rect.bounds.x + rect.bounds.width
        rect.ybr = rect.bounds.y + rect.bounds.height
        rect.center = new Point((rect.bounds.x + (rect.bounds.width / 2)) * @room().opts.currentScale,
        (rect.bounds.y + (rect.bounds.height / 2)) * @room().opts.currentScale)

        if cmX <= rect.center.x and cmY <= rect.center.y
          return x: rect.xtl, y: rect.ytl
        else if cmX >= rect.center.x and cmY <= rect.center.y
          return x: rect.xtr, y: rect.ytr
        else if cmX <= rect.center.x and cmY >= rect.center.y
          return x: rect.xbl, y: rect.ybr
        else if cmX >= rect.center.x and cmY >= rect.center.y
          return x: rect.xbr, y: rect.ybr

        return null

    redrawArrow: ($commentMin) ->
      commentMax = $commentMin[0].$maximized
      rect = $commentMin[0].rect
      arrow = $commentMin[0].arrow

      cmx = commentMax.position().left + (commentMax.width() / 2)
      cmy = commentMax.position().top + (commentMax.height() / 2)
      bp = @getArrowBindPoint($commentMin, cmx, cmy)

      if rect
        # rebind comment-minimized
        $commentMin.css({left: (bp.x * @opts().currentScale) - ($commentMin.width() / 2),
        top: (bp.y * @opts().currentScale) - ($commentMin.height() / 2)})

      return if arrow.isHidden

      bpx = if rect then bp.x else bp.x / @room().opts.currentScale
      bpy = if rect then bp.y else bp.y / @room().opts.currentScale
      zone = @getZone(commentMax.position().left, commentMax.position().top, bpx, bpy, commentMax.width(), commentMax.height())

      coords = @getArrowCoords($commentMin, zone)

      if coords == null
        arrow.opacity = 0
        return
      else
        arrow.opacity = 1

      arrow.segments[0].point.x = if rect then coords.x0 else coords.x0 / @opts().currentScale
      arrow.segments[0].point.y = if rect then coords.y0 else coords.y0 / @opts().currentScale
      arrow.segments[1].point.x = coords.x1 / @opts().currentScale
      arrow.segments[1].point.y = coords.y1 / @opts().currentScale
      arrow.segments[2].point.x = coords.x2 / @opts().currentScale
      arrow.segments[2].point.y = coords.y2 / @opts().currentScale

      @room().redrawWithThumb()

    removeComment: ($commentmin) ->
      if confirm("Are you sure?")
        $commentmin[0].$maximized.hide()
        $commentmin[0].arrow.opacity = 0
        $commentmin[0].rect.opacity = 0 if $commentmin[0].rect
        $commentmin.hide()

        if $commentmin[0].rect
          @room().history.add(type: "remove", tool: $commentmin[0].rect, eligible: true)
        else
          tool = {type: "comment", commentMin: $commentmin}
          @room().history.add({type: "remove", tool: tool, eligible: true})

        @room().socket.emit("commentRemove", $commentmin.elementId)
        @room().redraw()

    hideComment: ($commentmin) ->
      $commentmin[0].$maximized.hide()
      $commentmin[0].arrow.opacity = 0
      $commentmin[0].arrow.isHidden = true
      $commentmin.hide()
      $commentmin[0].rect.opacity = 0 if $commentmin[0].rect

    showComment: ($commentmin) ->
      $commentmin[0].$maximized.show()
      $commentmin[0].arrow.opacity = 1
      $commentmin[0].arrow.isHidden = false
      $commentmin.show()
      $commentmin[0].rect.opacity = 1 if $commentmin[0].rect

    foldComment: ($commentmin) ->
      $commentmin[0].$maximized.hide()
      $commentmin[0].arrow.opacity = 0
      $commentmin[0].arrow.isHidden = true
      $commentmin.show()

      @room().redraw()

    unfoldComment: ($commentmin) ->
      $commentmin[0].$maximized.show()
      $commentmin[0].arrow.opacity = 1
      $commentmin[0].arrow.isHidden = false

      # the comment position might have been changed.
      @redrawArrow($commentmin)

      $commentmin.hide() if $commentmin[0].rect

      @room().redraw()

    addCommentText: (commentMin, text, emit) ->
      commentContent = commentMin[0].$maximized.find(".comment-content")
      commentContent.prepend("<div class='comment-text'>#{text}</div>")

      @room().socket.emit("commentText", {elementId: commentMin.elementId, text: text}) if emit

  App.room.comments = new RoomComments
