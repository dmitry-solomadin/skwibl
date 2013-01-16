$ ->
  class RoomComments

    constructor: ->
      @SIDE_OFFSET = 15
      @CORNER_OFFSET = 18

      @COMMENT_RECTANGLE_ROUNDNESS = 8

      @COMMENT_RECT_DEFAULT_STYLE =
        opacity: 0.75
        dashArray: [8, 3]

    create: (x, y, rect, min, max, color, number) ->
      color = color or sharedOpts.color
      COMMENT_SHIFT_X = 75
      COMMENT_SHIFT_Y = -135

      if y < 100
        COMMENT_SHIFT_X = 75
        COMMENT_SHIFT_Y = 55

      reversedCoord = room.applyReverseCurrentScale new Point(x, y)
      min_x = if min then min.x else reversedCoord.x
      min_y = if min then min.y else reversedCoord.y

      commentMin = $("<div class='comment-minimized'></div>")
      commentMin.addClass("vis-hidden") if rect
      commentMin.css(left: min_x, top: min_y, borderColor: color).data("color", color)

      @setNumber commentMin, number

      commentMax = $("<div class='comment-maximized'></div>")
      commentMax.css(borderColor: color)
      max_x = if max then max.x else reversedCoord.x + COMMENT_SHIFT_X
      max_y = if max then max.y else reversedCoord.y + COMMENT_SHIFT_Y
      commentMax.css(left: max_x, top: max_y)
      commentHeader = $("<div class='comment-header'>" +
      "<div class='fr'><span class='comment-minimize'></span><span class='comment-remove'></span></div>" +
      "</div>")

      commentHeader.find(".comment-minimize").on "click", => @foldComment(commentMin)
      commentHeader.find(".comment-remove").on "click", => @removeComment(commentMin)
      commentMin.on "mousedown", => @unfoldComment(commentMin, false)

      commentMax.append(commentHeader)
      commentContent = $("<div class='comment-content'><div class='comment-content-inner'></div>" +
      "<div class='comment-content-actions'><textarea class='comment-reply' placeholder='Type a comment...'></textarea>" +
      "<input type='button' class='btn small-btn fr comment-send hide' value='Send'>" +
      "<input type='button' class='btn small-btn fr edit-cancel hide' value='Cancel edit'></div>" +
      "</div>")
      $(commentContent).data("hidden", "false")
      commentMax.append(commentContent)

      commentHeader[0].commentMin = commentMin
      commentHeader.drags
        onDrag: (dx, dy) =>
          commentMax.css(left: (commentMax.position().left + dx) + "px", top: (commentMax.position().top + dy) + "px")
          @redrawArrow(commentMin)
        onAfterDrag: =>
          room.socket.emit("commentUpdate", room.socketHelper.prepareCommentToSend(commentMin))
          room.redrawWithThumb()

      commentMin.drags
        onDrag: (dx, dy) =>
          commentMin.css({left: (commentMin.position().left + dx) + "px", top: (commentMin.position().top + dy) + "px"})
          @redrawArrow(commentMin)
        onAfterDrag: =>
          room.socket.emit("commentUpdate", room.socketHelper.prepareCommentToSend(commentMin))
          room.redrawWithThumb()

      $(document).off("click.toggleCommentButtons").on "click.toggleCommentButtons", (evt) =>
        for commentSendButton in $(".comment-send:visible")
          # do not make send button invisible if comment in editing mode.
          unless $(commentSendButton).parent().find(".edit-cancel:visible")[0]
            $(commentSendButton).hide()
            @redrawArrow(commentMin)

        $(evt.target).parent(".comment-content-actions").find(".comment-send").show() if evt.target

      $(commentMax).find(".comment-send").on "click", =>
        editCancelButton = commentMax.find(".edit-cancel:visible")[0]
        if editCancelButton
          commentTextarea = commentMax.find(".comment-reply")
          @doEditText $(editCancelButton).data("edited-comment-text-id"), commentTextarea.val(), true
          commentMax.find(".edit-cancel").click()
        else
          commentTextarea = commentMax.find(".comment-reply")
          @addCommentText commentMin, text: commentTextarea.val()
          commentTextarea.val("")

      $(commentMax).find(".edit-cancel").on "click", =>
        commentMax.find(".comment-reply").val("")
        $(commentMax).find(".edit-cancel").hide()

      commentMax[0].coords = ->
        left = $(this).position().left
        top = $(this).position().top
        height = $(this).height()
        width = $(this).width()

        tl = room.applyCurrentScale new Point(left, top)
        tr = room.applyCurrentScale new Point(left + width, top)
        bl = room.applyCurrentScale new Point(left, top + height)
        br = room.applyCurrentScale new Point(left + width, top + height)
        wh = room.applyCurrentScale new Point(width, height)

        xtl: tl.x, ytl: tl.y
        xtr: tr.x, ytr: tr.y
        xbl: bl.x, ybl: bl.y
        xbr: br.x, ybr: br.y
        w: wh.x, h: wh.y

      commentMin[0].$maximized = commentMax

      if rect
        commentMin[0].rect = rect
        rect.commentMin = commentMin

      $("#commentsDiv").prepend(commentMin)
      $("#commentsDiv").prepend(commentMax)

      coords = @getArrowCoords commentMin
      path = new Path()
      path.strokeColor = color
      path.strokeWidth = "1"
      path.fillColor = "#FCFCFC"
      path.add new Point(coords.x0, coords.y0)
      path.add new Point(coords.x1, coords.y1)
      path.add new Point(coords.x2, coords.y2)
      path.closed = true
      paper.project.activeLayer.addChild(path)

      commentMin[0].arrow = path

      commentMin

    getZone: (commentMin) ->
      bp = @getArrowBindPoint commentMin
      c = commentMin[0].$maximized[0].coords()

      return 1 if bp.x <= c.xtl and bp.y <= c.ytl
      return 2 if bp.x > c.xtl and bp.x < c.xtr and bp.y < c.ytl
      return 3 if bp.x >= c.xtr and bp.y <= c.ytr
      return 4 if bp.x < c.xtl and bp.y < c.ybl and bp.y > c.ytl
      return 5 if bp.x >= c.xtl and bp.x <= c.xtr and bp.y <= c.ybl and bp.y >= c.ytl
      return 6 if bp.x > c.xtr and bp.y < c.ybr and bp.y > c.ytr
      return 7 if bp.x <= c.xbl and bp.y >= c.ybl
      return 8 if bp.x > c.xbl and bp.x < c.xbr and bp.y > c.ybl
      return 9 if bp.x >= c.xbr and bp.y >= c.ybr

    getArrowPos: (zone, c) ->
      x1 = 0
      y1 = 0
      x2 = 0
      y2 = 0
      w2 = c.w / 2
      h2 = c.h / 2

      switch zone
        when 1
          x1 = c.xtl
          y1 = c.ytl + @CORNER_OFFSET
          x2 = c.xtl + @CORNER_OFFSET
          y2 = c.ytl
        when 2
          x2 = c.xtl + w2 + @SIDE_OFFSET
          y2 = c.ytl
          x1 = c.xtl + w2 - @SIDE_OFFSET
          y1 = c.ytl
        when 3
          x1 = c.xtr - @CORNER_OFFSET
          y1 = c.ytr
          x2 = c.xtr
          y2 = c.ytr + @CORNER_OFFSET
        when 4
          x1 = c.xtl
          y1 = c.ytl + h2 + @SIDE_OFFSET
          x2 = c.xtl
          y2 = c.ytl + h2 - @SIDE_OFFSET
        when 6
          x1 = c.xtr
          y1 = c.ytr + h2 - @SIDE_OFFSET
          x2 = c.xtr
          y2 = c.ytr + h2 + @SIDE_OFFSET
        when 7
          x1 = c.xbl + @CORNER_OFFSET
          y1 = c.ybl
          x2 = c.xbl
          y2 = c.ybl - @CORNER_OFFSET
        when 8
          x1 = c.xbl + w2 + @SIDE_OFFSET
          y1 = c.ybl
          x2 = c.xbl + w2 - @SIDE_OFFSET
          y2 = c.ybl
        when 9
          x1 = c.xbr
          y1 = c.ybr - @CORNER_OFFSET
          x2 = c.xbr - @CORNER_OFFSET
          y2 = c.ybr

      x1: x1, y1: y1, x2: x2, y2: y2

    getArrowCoords: ($commentMin) ->
      commentMax = $commentMin[0].$maximized

      zone = @getZone $commentMin
      return null if zone is 5

      bp = @getArrowBindPoint $commentMin
      c = commentMax[0].coords()
      pos = @getArrowPos zone, c

      x0: bp.x, y0: bp.y
      x1: pos.x1, y1: pos.y1
      x2: pos.x2, y2: pos.y2

    getArrowBindPoint: ($commentMin) ->
      rect = $commentMin[0].rect

      if rect
        c = $commentMin[0].$maximized[0].coords()
        cmX = c.xtl + (c.w / 2)
        cmY = c.ytl + (c.h / 2)

        b = rect.bounds

        if cmX <= b.center.x and cmY <= b.center.y
          return x: b.topLeft.x, y: b.topLeft.y
        else if cmX >= b.center.x and cmY <= b.center.y
          return x: b.topRight.x, y: b.topRight.y
        else if cmX <= b.center.x and cmY >= b.center.y
          return x: b.bottomLeft.x, y: b.bottomLeft.y
        else if cmX >= b.center.x and cmY >= b.center.y
          return x: b.bottomRight.x, y: b.bottomRight.y

        return null
      else
        x = $commentMin.position().left + ($commentMin.width() / 2)
        y = $commentMin.position().top + ($commentMin.height() / 2)
        room.applyCurrentScale new Point(x, y)

    redrawArrow: ($commentMin) ->
      arrow = $commentMin[0].arrow
      return if arrow.isHidden

      coords = @getArrowCoords $commentMin

      if coords
        arrow.opacity = 1
      else
        arrow.opacity = 0
        return

      arrow.segments[0].point.x = coords.x0
      arrow.segments[0].point.y = coords.y0
      arrow.segments[1].point.x = coords.x1
      arrow.segments[1].point.y = coords.y1
      arrow.segments[2].point.x = coords.x2
      arrow.segments[2].point.y = coords.y2

      room.redraw()

    assignBringToFront: ->
      $(document).on "mousedown", "#commentsDiv .comment-maximized", ->
        maxZIndex = 1
        for comment in $(".comment-maximized:visible")
          commentZIndex = $(comment).css("z-index")
          maxZIndex = commentZIndex if commentZIndex > maxZIndex

        $(@).css("z-index", parseInt(maxZIndex) + 1)

    translate: (commentMin, delta) ->
      unscaledD = room.applyReverseCurrentScale delta
      commentMin.css
        top: commentMin.position().top + unscaledD.y
        left: commentMin.position().left + unscaledD.x
      commentMin[0].arrow.translate delta
      maximized = commentMin[0].$maximized
      maximized.css
        top: maximized.position().top + unscaledD.y
        left: maximized.position().left + unscaledD.x
      commentMin[0].rect.translate delta if commentMin[0].rect

    removeComment: ($commentmin) ->
      if confirm("Are you sure?")
        $commentmin[0].$maximized.hide()
        $commentmin[0].arrow.opacity = 0
        $commentmin[0].rect.opacity = 0 if $commentmin[0].rect
        $commentmin.hide()

        if $commentmin[0].rect
          room.history.add(actionType: "remove", tool: $commentmin[0].rect, eligible: true)
        else
          tool = {actionType: "comment", commentMin: $commentmin}
          room.history.add({actionType: "remove", tool: tool, eligible: true})

        for commentText in $commentmin[0].$maximized.find(".comment-text")
          $("#todo-tab-inner").find("#" + commentText.id).remove()
        @recalcTasksCount()

        room.socket.emit("commentRemove", $commentmin.elementId)
        room.redraw()

    hideComment: ($commentmin) ->
      $commentmin[0].$maximized.hide()
      $commentmin[0].arrow.opacity = 0
      $commentmin[0].arrow.isHidden = true
      $commentmin.hide()
      $commentmin[0].rect.opacity = 0 if $commentmin[0].rect

    showComment: ($commentmin) ->
      folded = $commentmin[0].arrow.isFolded

      $commentmin[0].$maximized.show()

      unless folded
        $commentmin[0].arrow.opacity = 1
        $commentmin[0].arrow.isHidden = false

      $commentmin.show()
      $commentmin[0].rect.opacity = 1 if $commentmin[0].rect

    toggleComments: ->
      if $("#toggleComments").hasClass("active")
        @foldAll()
        $("#toggleComments").removeClass("active").html("Show comments").attr("data-original-title", "Show all comments")
      else
        @unfoldAll()
        $("#toggleComments").addClass("active").html("Hide comments").attr("data-original-title", "Hide all comments")

    foldAll: ->
      for savedOpt in room.savedOpts
        @foldComment(element.commentMin) for element in savedOpt.historytools.allHistory when element.commentMin

    unfoldAll: ->
      for savedOpt in room.savedOpts
        for element in savedOpt.historytools.allHistory when element.commentMin
          skipUnfoldArrow = opts.canvasId isnt savedOpt.canvasId
          @unfoldComment(element.commentMin, skipUnfoldArrow)

    foldComment: ($commentmin) ->
      $commentmin[0].$maximized.css("visibility", "hidden")
      $commentmin[0].arrow.opacity = 0
      $commentmin[0].arrow.isHidden = true
      $commentmin[0].arrow.isFolded = true
      $commentmin.css("visibility", "visible")

      room.redrawWithThumb()

    unfoldComment: ($commentmin, skipUnfoldArrow) ->
      $commentmin[0].$maximized.css("visibility", "visible")

      unless skipUnfoldArrow
        $commentmin[0].arrow.opacity = 1
        $commentmin[0].arrow.isHidden = false
        $commentmin[0].arrow.isFolded = false

        # the comment position might have been changed.
        @redrawArrow($commentmin)

      $commentmin.css("visibility", "hidden") if $commentmin[0].rect

      room.redrawWithThumb()

    addCommentText: (commentMin, commentText) ->
      return if $.trim(commentText.text).length is 0

      emit = not commentText.elementId?
      elementId = commentText.elementId or room.generateId()
      owner = commentText.owner or $("#uid").val()
      time = commentText.time or Date.now()
      commentContent = commentMin[0].$maximized.find(".comment-content-inner")

      user = App.chat.getUserById owner

      commentsCount = commentContent.children().length

      hiddenCommentsCount = commentsCount - 2
      showCommentsText = "Show #{commentsCount - 2} previous #{if hiddenCommentsCount is 1 then 'comment' else 'comments'}"
      if commentsCount is 3
        $(commentContent).parent().data("hidden", "true")
        commentContent.parent().prepend "<div class='comment-show-comments'>#{showCommentsText}</div>"

        showComments = ->
          $(commentContent).parent().data("hidden", "false")
          $(commentContent).parent().find(".comment-show-comments").html("Hide comments")
          commentContent.children().slideDown("fast")
          $(commentContent).parent().find(".comment-show-comments").off("click.comments").on "click.comments", -> hideComments()

        hideComments = =>
          $(commentContent).parent().data("hidden", "true")
          @initHideCommentsBlock(commentContent)
          $(commentContent).parent().find(".comment-show-comments").off("click.comments").on "click.comments", -> showComments()

        $(commentContent).parent().find(".comment-show-comments").click -> showComments()

      showCommentsDiv = $(commentContent).parent().find(".comment-show-comments")
      showCommentsDiv.html(showCommentsText) if showCommentsDiv[0]

      isCommentOwner = "#{owner}" is "#{$("#uid").val()}"

      commentContent.append(
        "<div id='commentText#{elementId}' class='comment-text' data-comment-id='#{commentMin.elementId}'
           data-element-id='#{elementId}' data-owner='#{owner}' data-time='#{time}'>
             <div class='comment-ribbon-wrapper'><div class='comment-ribbon comment-ribbon-blue'>todo</div></div>
             <div class='comment-avatar'><img src='#{user.picture}' width='32'/></div>
             <div class='comment-heading'>
                 <div class='comment-author'>#{user.displayName}</div>
                 <div class='comment-time'>at #{moment(parseFloat(time)).format("DD.MM.YYYY HH:mm")}</div>
             </div>
             <div class='the-comment-text'>#{commentText.text}</div>
             <div class='comment-actions'>
                 <a href='#' class='markAsTodoLink' onclick='App.room.comments.markAsTodo(#{elementId}, true); return false;'>todo</a>
                 <a href='#' class='editCommentTextLink' onclick='App.room.comments.editText(#{elementId}); return false;'>edit</a>
                 <a href='#' class='removeCommentTextLink' onclick='App.room.comments.removeText(#{elementId}, true); return false;'>remove</a>
             </div>
         </div>")

      commentContent.find(".editCommentTextLink").hide() unless isCommentOwner

      if commentText.todo
        commentTextDiv = commentContent.find("#commentText#{elementId}")
        commentTextDiv.addClass("todo")
        commentTextDiv.find(".markAsTodoLink").remove()

        if commentText.resolved
          commentTextDiv.find(".comment-actions").prepend("<a href='#' class='resolve-link' onclick='App.room.comments.reopenTodo(#{elementId}, true); return false;'>reopen</a>")
          commentTextDiv.find(".comment-ribbon").removeClass("comment-ribbon-blue").addClass("comment-ribbon-green").html("resolved")
          commentTextDiv.addClass("resolved")
        else
          commentTextDiv.find(".comment-actions").prepend("<a href='#' class='resolve-link' onclick='App.room.comments.resolveTodo(#{elementId}, true); return false;'>resolve</a>")

      for comment, index in commentContent.children()
        $(comment).hide() if commentsCount - index > 2

      if emit
        room.socket.emit "commentText",
          elementId: elementId
          commentId: commentMin.elementId
          pid: $("#pid").val()
          owner: owner
          text: commentText.text

    initHideCommentsBlock: (commentContent) ->
      commentsCount = commentContent.children().length
      hiddenCommentsCount = commentsCount - 3
      showCommentsText = "Show #{commentsCount - 3} previous #{if hiddenCommentsCount is 1 then 'comment' else 'comments'}"
      $(commentContent).parent().find(".comment-show-comments").html(showCommentsText)
      for comment, index in commentContent.children()
        if commentsCount - index > 3
          $(comment).slideUp("fast")
        else
          $(comment).slideDown("fast")

    editText: (elementId) ->
      comment = $("#commentText#{elementId}")
      replyBox = comment.parent().parent().find(".comment-reply")
      commentText = comment.find(".the-comment-text").html()

      # show the buttons
      comment.parent().parent().find(".comment-send").val("Save").show()
      comment.parent().parent().find(".edit-cancel").data("edited-comment-text-id", elementId).show()

      replyBox.val(commentText)

    doEditText: (elementId, newText, emit) ->
      comment = $("#commentText#{elementId}")
      comment.find(".the-comment-text").html(newText).effect("highlight", {}, 800);
      if emit
        owner = comment.data("owner")
        room.socket.emit "updateCommentText", elementId: elementId, text: newText, owner: owner

    removeText: (elementId, emit) ->
      comment = $("#commentText#{elementId}")
      commentContent = $(comment).parent()
      comment.slideUp "fast", =>
        $(comment).remove()

        $("#todo-tab-inner").find("#commentText#{elementId}").remove()
        @recalcTasksCount()

        @initHideCommentsBlock commentContent if $(commentContent).parent().data("hidden") is "true"
        room.socket.emit "removeCommentText", elementId if emit

    markAsTodo: (elementId, emit) ->
      comment = $("#commentText#{elementId}")
      comment.addClass("todo")
      comment.find(".markAsTodoLink").replaceWith("<a href='#' class='resolve-link'
        onclick='App.room.comments.resolveTodo(#{elementId}, true); return false;'>resolve</a>")

      @addTodo $("#commentText#{elementId}")

      room.socket.emit "markAsTodo", elementId if emit

    resolveTodo: (elementId, emit) ->
      comment = $("#commentText#{elementId}")
      comment.addClass("resolved")
      comment.find(".comment-ribbon").removeClass("comment-ribbon-blue").addClass("comment-ribbon-green").html("resolved")
      comment.find(".resolve-link").replaceWith("<a href='#' class='resolve-link'
        onclick='App.room.comments.reopenTodo(#{elementId}, true); return false;'>reopen</a>")

      @addTodo $("#commentText#{elementId}")

      room.socket.emit "resolveTodo", elementId if emit

    reopenTodo: (elementId, emit) ->
      comment = $("#commentText#{elementId}")
      comment.removeClass("resolved")
      comment.find(".comment-ribbon").addClass("comment-ribbon-blue").removeClass("comment-ribbon-green").html("todo")
      comment.find(".resolve-link").replaceWith("<a href='#' class='resolve-link'
       onclick='App.room.comments.resolveTodo(#{elementId}, true); return false;'>resolve</a>")

      @addTodo $("#commentText#{elementId}")

      room.socket.emit "reopenTodo", elementId if emit

    addTodo: (commentText) ->
      if $("#todo-tab-inner").children().length is 0
        # if it's the first comment added let's prepare todolist structure
        $("#todo-tab-inner").html("")
        $("#todo-tab-inner").append(
          "<div class='openTab' onclick='App.room.comments.viewOpen()'>0 open</div>
           <div class='resolvedTab' onclick='App.room.comments.viewResolved()'>0 resolved</div>")
        $("#todo-tab-inner").append("<div class='openList'></div><div class='resolvedList'></div>")

      commentText = commentText.clone()
      commentText[0].id = commentText[0].id + "cloned"
      commentText.css("cursor", "pointer")
      commentText.find(".editCommentTextLink, .removeCommentTextLink").remove()
      commentText.on 'click', =>
        @highlightComment commentText.data("element-id")

      $("#todo-tab-inner").find("#" + commentText[0].id).remove()
      if commentText.hasClass("resolved")
        $("#todo-tab-inner").find(".resolvedList").append(commentText)
      else
        $("#todo-tab-inner").find(".openList").append(commentText)
      commentText.show()
      #it may be hidden in the main view.

      @recalcTasksCount()

    recalcTasksCount: ->
      $(".resolvedTab").html($(".resolvedList").children().length + " resolved")
      $(".openTab").html($(".openList").children().length + " open")

    viewResolved: ->
      $(".openList").hide()
      $(".resolvedList").show()

    viewOpen: ->
      $(".resolvedList").hide()
      $(".openList").show()

    highlightComment: (commentTextId) ->
      commentText = $("#commentText#{commentTextId}")

      result = room.helper.findByElementIdAllCanvases commentText.data("comment-id")

      room.canvas.findThumbByCanvasId(result.canvasId).click()

      comment = result.element
      @unfoldComment comment.commentMin, false

      commentText.effect("highlight", {}, 800);

      commentX = commentText.offset().left - (room.canvas.getViewportAdjustX() / 2 )
      commentY = commentText.offset().top + (room.canvas.getViewportAdjustY()  / 2 )

      commentWidth = commentText.width()
      commentHeight = commentText.height()

      canvasX = paper.view.center.x
      canvasY = paper.view.center.y

      diffX = canvasX - commentX - (commentWidth / 2)
      diffY = canvasY - commentY - (commentHeight / 2)

      room.items.pan new Point(diffX, diffY)
      room.redrawWithThumb()

    setNumber: (commentMin, newNumber) ->
      commentMin.html("X") unless newNumber

      intNumber = parseInt newNumber
      if intNumber >= 1000
        commentMin.css fontSize: "9px"
      if intNumber >= 100
        commentMin.css fontSize: "11px"
      if intNumber >= 10
        commentMin.css fontSize: "14px"
      else
        commentMin.css fontSize: "18px"

      commentMin.html newNumber

    updateCommentNumber: (data) ->
      comment = room.helper.findByElementId(data.elementId)
      @setNumber(comment.commentMin, data.newNumber)

  App.room.comments = new RoomComments
