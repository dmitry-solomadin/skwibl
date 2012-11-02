$ ->
  class Room
    constructor: ->
      @opts = {}
      @savedOpts = new Array
      @defaultOpts =
        tooltype: 'line'
        color: '#404040'
        defaultWidth: 2
        currentScale: 1
        nextId: 1
        opacity: 1

    init: ->
      @initOpts()

      $("#toolSelect > li, #panTool, #selectTool").on "click", ->
        opts.tooltype = $(@).data("tooltype")

      $('.color').click ->
        $('.color').removeClass('activen')
        opts.color = $(@).attr('data-color')
        $(@).addClass('activen')

      $(document).on "click", "#canvasSelectDiv a", ->
        App.room.canvas.selectThumb(@)
        false

      @helper.initUploader()
      @helper.initHotkeys()

      # disable canvas text selection for cursor change
      canvas = $("#myCanvas")[0]
      canvas.onselectstart = -> return false
      canvas.onmousedown = -> return false

      false

    initOpts: ->
      @opts = {}
      window.opts = @opts
      $.extend(@opts, @defaultOpts)
      @opts.historytools =
        eligibleHistory: new Array
        allHistory: new Array
      @savedOpts.push(@opts)

    setOpts: (opts) ->
      @opts = opts
      window.opts = opts

    # Mouse events handling

    onMouseMove: (canvas, event) ->
      event.point = event.point.transform(new Matrix(1 / @opts.currentScale, 0, 0, 1 / @opts.currentScale, 0, 0))

      $(canvas).css({cursor: "default"})

      selectedTool = @opts.selectedTool
      if selectedTool && selectedTool.selectionRect
        if selectedTool.selectionRect.bottomRightScaler.bounds.contains(event.point)
          $(canvas).css(cursor: "se-resize")
        else if selectedTool.selectionRect.topLeftScaler.bounds.contains(event.point)
          $(canvas).css(cursor: "nw-resize")
        else if selectedTool.selectionRect.topRightScaler.bounds.contains(event.point)
          $(canvas).css(cursor: "ne-resize")
        else if selectedTool.selectionRect.bottomLeftScaler.bounds.contains(event.point)
          $(canvas).css(cursor: "sw-resize")
        else if selectedTool.selectionRect.removeButton and selectedTool.selectionRect.removeButton.bounds.contains(event.point)
          $(canvas).css(cursor: "pointer")

    onMouseDown: (canvas, event) ->
      event.point = event.point.transform(new Matrix(1 / @opts.currentScale, 0, 0, 1 / @opts.currentScale, 0, 0))
      ;

      $("#removeSelected").addClass("disabled")
      if @opts.selectedTool && @opts.selectedTool.selectionRect
        @opts.selectedTool.selectionRect.remove()

      @opts.commentRect = null

      if @opts.tooltype == 'line'
        @items.create(new Path())
      else if @opts.tooltype == 'highligher'
        @items.create(new Path(), {color: @opts.color, width: 15, opacity: 0.7})
      else if @opts.tooltype == 'straightline'
        @items.create(new Path())
        ;
        @opts.tool.add(event.point) if @opts.tool.segments.length == 0
        @opts.tool.add(event.point)
      else if @opts.tooltype == 'arrow'
        arrow = new Path()
        arrow.arrow = arrow
        @items.create(arrow)
        @opts.tool.add(event.point) if @opts.tool.segments.length == 0
        @opts.tool.add(event.point)
        @opts.tool.lineStart = event.point
      else if @opts.tooltype == "select"
        @items.testSelect(event.point)
        @items.drawSelectRect(event.point)

      # this should be here because sometimes mouse up event won't fire.
      if @opts.tooltype == 'line' or @opts.tooltype == 'highligher'
        @opts.tool.eligible = true
        @history.add()

    onMouseDrag: (canvas, event) ->
      event.point = event.point.transform(new Matrix(1 / @opts.currentScale, 0, 0, 1 / @opts.currentScale, 0, 0))

      deltaPoint = event.downPoint.subtract(event.point)

      if @opts.tooltype == 'line'
        @opts.tool.add(event.point)
        @opts.tool.smooth()
      else if @opts.tooltype == 'highligher'
        @opts.tool.add(event.point)
        @opts.tool.smooth()
      else if @opts.tooltype == 'circle'
        rectangle = new Rectangle(event.point.x, event.point.y, deltaPoint.x, deltaPoint.y)
        @items.create(new Path.Oval(rectangle))
        @opts.tool.removeOnDrag()
      else if @opts.tooltype == 'rectangle'
        rectangle = new Rectangle(event.point.x, event.point.y, deltaPoint.x, deltaPoint.y)
        @items.create(new Path.Rectangle(rectangle))
        @opts.tool.removeOnDrag()
      else if @opts.tooltype == 'comment'
        if deltaPoint.x < 0 and deltaPoint.y < 0
          x = event.downPoint.x
          y = event.downPoint.y
          w = Math.abs(deltaPoint.x)
          h = Math.abs(deltaPoint.y)
        else
          x = event.point.x
          y = event.point.y
          w = deltaPoint.x
          h = deltaPoint.y

        rectangle = new Path.RoundRectangle(x, y, w, h,
        @comments.COMMENT_RECTANGLE_ROUNDNESS, @comments.COMMENT_RECTANGLE_ROUNDNESS)
        @opts.commentRect = rectangle
        @items.create(rectangle, @comments.COMMENT_STYLE)
        @opts.tool.removeOnDrag()
      else if @opts.tooltype == 'straightline'
        @opts.tool.lastSegment.point = event.point
      else if @opts.tooltype == 'arrow'
        arrow = @opts.tool.arrow
        arrow.lastSegment.point = event.point

        arrowGroup = new Group([arrow])
        arrowGroup.arrow = arrow
        arrowGroup.drawTriangle = ->
          vector = @arrow.lastSegment.point - @arrow.segments[0].point
          vector = vector.normalize(10)
          if @triangle
            @triangle.segments[0].point = @arrow.lastSegment.point + vector.rotate(135)
            @triangle.segments[1].point = @arrow.lastSegment.point
            @triangle.segments[2].point = @arrow.lastSegment.point + vector.rotate(-135)
          else
            triangle = new Path([
              @arrow.lastSegment.point + vector.rotate(135)
              @arrow.lastSegment.point
              @arrow.lastSegment.point + vector.rotate(-135)
            ])
            @triangle = triangle
            @addChild(triangle)

          @triangle

        triangle = arrowGroup.drawTriangle()
        @items.create(triangle)

        @opts.tool = arrowGroup

        triangle.removeOnDrag()
      else if @opts.tooltype == 'pan'
        for element in @opts.historytools.allHistory
          if element.commentMin
            commentRect = element.type != "comment"

            dx = @opts.currentScale * event.delta.x
            dy = @opts.currentScale * event.delta.y

            element.commentMin.css({top: element.commentMin.position().top + dy,
            left: element.commentMin.position().left + dx})
            element.commentMin[0].arrow.translate(event.delta)
            element.commentMin[0].$maximized.css({top: element.commentMin[0].$maximized.position().top + dy,
            left: element.commentMin[0].$maximized.position().left + dx})

            element.translate(event.delta) if commentRect
          else if !element.type and element.translate
            element.translate(event.delta)
      else if @opts.tooltype == 'select'
        if @opts.selectedTool and @opts.selectedTool.scalersSelected
          tool = @opts.selectedTool

          scaleZone = @items.getReflectZone(tool, event.point.x, event.point.y)
          if scaleZone then tool.scaleZone = scaleZone else scaleZone = tool.scaleZone

          zx = scaleZone.zx
          zy = scaleZone.zy
          scalePoint = scaleZone.point

          dx = event.delta.x
          dy = event.delta.y

          scaleFactors = @items.getScaleFactors(tool, zx, zy, dx, dy)
          sx = scaleFactors.sx
          sy = scaleFactors.sy

          # scale tool
          @items.doScale(tool, sx, sy, scalePoint)

          tool.selectionRect.remove()
          tool.selectionRect = @items.createSelectionRectangle(tool)
        else
          @items.translateSelected(event.delta)

        # redraw comment arrow if there is one.
        if @opts.selectedTool.commentMin
          @comments.redrawArrow(@opts.selectedTool.commentMin)

    onMouseUp: (canvas, event) ->
      event.point = event.point.transform(new Matrix(1 / @opts.currentScale, 0, 0, 1 / @opts.currentScale, 0, 0))

      if @opts.tooltype == 'line'
        @opts.tool.add(event.point)
        @opts.tool.simplify(10)
      if @opts.tooltype == 'highligher'
        @opts.tool.add(event.point)
        @opts.tool.simplify(10)
      if @opts.tooltype == "comment"
        commentMin = @comments.create(event.point.x, event.point.y, @opts.commentRect)

        if @opts.commentRect
          @opts.commentRect.commentMin = commentMin

      if @opts.tool
        @opts.tool.tooltype = @opts.tooltype

      if @opts.tooltype == 'straightline' or @opts.tooltype == 'arrow' or
      @opts.tooltype == 'circle' or @opts.tooltype == 'rectangle'
        @opts.tool.eligible = true
        @history.add()

      if @opts.tooltype == 'comment'
        if @opts.commentRect
          @opts.tool.eligible = true
          @history.add()
        else
          @history.add(type: "comment", commentMin: commentMin, eligible: true)

      if @opts.tooltype == 'straightline' or @opts.tooltype == 'arrow' or @opts.tooltype == 'circle' or
      @opts.tooltype == 'rectangle' or @opts.tooltype == 'line' or @opts.tooltype == 'highligher'
        @opts.tool.elementId = @getNextIdAndIncrement()
        @socket.emit("elementUpdate", @socketHelper.prepareElementToSend(@opts.tool))
        @socket.emit("nextId")
      else if @opts.tooltype == "comment"
        commentMin.elementId = @getNextIdAndIncrement()
        @socket.emit("commentUpdate", @socketHelper.prepareCommentToSend(commentMin))
        @socket.emit("nextId")
      else if @opts.tooltype == 'select' && @opts.selectedTool
        @socket.emit("elementUpdate", @socketHelper.prepareElementToSend(@opts.selectedTool))


      @opts.tooltype = "select" if @opts.tooltype == 'comment'

      @canvas.updateSelectedThumb()

    # Misc methods

    getNextIdAndIncrement: ->
      prevId = @opts.nextId
      @opts.nextId = @opts.nextId + 1
      prevId

    redraw: ->
      paper.view.draw()

    redrawWithThumb: ->
      @redraw()
      @canvas.updateSelectedThumb()

  room = new Room
  $.extend(App.room, room)

$ ->
  return unless currentPage("projects/show")

  # paper.install(window) causes errors upon defining getters for 'project', so we use this code
  for key of paper
    window[key] = paper[key] if not /^(version|_id|load)/.test(key) and not window[key]?

  paper.setup($('#myCanvas')[0])

  # initilazing events
  tool = new paper.Tool()
  tool.onMouseDown = (event) -> App.room.onMouseDown($("#myCanvas"), event)
  tool.onMouseDrag = (event) -> App.room.onMouseDrag($("#myCanvas"), event)
  tool.onMouseUp = (event) -> App.room.onMouseUp($("#myCanvas"), event)
  tool.onMouseMove = (event) -> App.room.onMouseMove($("#myCanvas"), event)

  App.room.init()

  window.room = App.room
  window.opts = App.room.opts

  # resizing canvas
  paper.view.setViewSize(Rectangle.create(0, 0, $("body").width(), $("body").height()).getSize())
