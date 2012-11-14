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
        opacity: 1

    init: ->
      @initOpts()

      $(".toolTypeChanger").on "click", ->
        opts.tooltype = $(@).data("tooltype")

      $('#colorSelect .color').click ->
        $('#colorSelect .color').removeClass('activen')
        opts.color = $(@).attr('data-color')
        $(@).addClass('activen')

        $(".colorSelected").css("background", opts.color)

      $(document).on "click", "#canvasSelectDiv a", ->
        App.room.canvas.selectThumb(@, true)
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
      event.point = @applyCurrentScale(event.point)

      canvas.css({cursor: "default"})

      selectedTool = @items.selected()
      if selectedTool && selectedTool.selectionRect
        if selectedTool.selectionRect.bottomRightScaler.bounds.contains(event.point)
          canvas.css(cursor: "se-resize")
        else if selectedTool.selectionRect.topLeftScaler.bounds.contains(event.point)
          canvas.css(cursor: "nw-resize")
        else if selectedTool.selectionRect.topRightScaler.bounds.contains(event.point)
          canvas.css(cursor: "ne-resize")
        else if selectedTool.selectionRect.bottomLeftScaler.bounds.contains(event.point)
          canvas.css(cursor: "sw-resize")
        else if selectedTool.selectionRect.removeButton and selectedTool.selectionRect.removeButton.bounds.contains(event.point)
          canvas.css(cursor: "pointer")

    onMouseDown: (canvas, event) ->
      event.point = @applyCurrentScale(event.point)

      $("#removeSelected").addClass("disabled")

      @items.selected().selectionRect.remove() if @items.selected() && @items.selected().selectionRect

      @opts.tool = null

      switch @opts.tooltype
        when 'line'
          @items.create(new Path())
        when 'highligher'
          @items.create(new Path(), {color: @opts.color, width: 15, opacity: 0.7})
        when 'straightline'
          @items.create(new Path())
          @opts.tool.add(event.point) for [0..1]
        when 'arrow'
          arrow = new Path()
          arrow.arrow = arrow
          @items.create(arrow)
          @opts.tool.add(event.point) for [0..1]
          @opts.tool.lineStart = event.point
        when "select"
          @items.testSelect(event.point)
          @items.drawSelectRect(event.point)

    onMouseDrag: (canvas, event) ->
      event.point = @applyCurrentScale(event.point)

      deltaPoint = event.downPoint.subtract(event.point)

      switch @opts.tooltype
        when 'line'
          @opts.tool.add(event.point)
          @opts.tool.smooth()
        when 'highligher'
          @opts.tool.add(event.point)
          @opts.tool.smooth()
        when 'circle'
          rectangle = new Rectangle(event.point.x, event.point.y, deltaPoint.x, deltaPoint.y)
          @items.create(new Path.Oval(rectangle))
          @opts.tool.removeOnDrag()
        when 'rectangle'
          rectangle = new Rectangle(event.point.x, event.point.y, deltaPoint.x, deltaPoint.y)
          @items.create(new Path.Rectangle(rectangle))
          @opts.tool.removeOnDrag()
        when 'comment'
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
          rectangle.isCommentRect = true
          @items.create(rectangle, @comments.COMMENT_STYLE)
          @opts.tool.removeOnDrag()
        when 'straightline'
          @opts.tool.lastSegment.point = event.point
        when 'arrow'
          arrow = @opts.tool.arrow
          arrow.lastSegment.point = event.point

          arrowGroup = new Group([arrow])
          arrowGroup.arrow = arrow
          arrowGroup.drawTriangle = ->
            vector = new Point(@arrow.lastSegment.point.x - @arrow.segments[0].point.x, @arrow.lastSegment.point.y - @arrow.segments[0].point.y)
            vector = vector.normalize(10)
            vrplus = vector.rotate(135)
            vrminus = vector.rotate(-135)
            if @triangle
              @triangle.segments[0].point = new Point(@arrow.lastSegment.point.x + vrplus.x, @arrow.lastSegment.point.y + vrplus.y)
              @triangle.segments[1].point = @arrow.lastSegment.point
              @triangle.segments[2].point = new Point(@arrow.lastSegment.point.x + vrminus.x, @arrow.lastSegment.point.y + vrminus.y)
            else
              triangle = new Path([
                new Point(@arrow.lastSegment.point.x + vrplus.x, @arrow.lastSegment.point.y + vrplus.y)
                @arrow.lastSegment.point
                new Point(@arrow.lastSegment.point.x + vrminus.x, @arrow.lastSegment.point.y + vrminus.y)
              ])
              @triangle = triangle
              @addChild(triangle)

            @triangle

          triangle = arrowGroup.drawTriangle()
          @items.create(triangle)

          @opts.tool = arrowGroup

          triangle.removeOnDrag()
        when 'pan'
          @items.pan(event.delta.x, event.delta.y)
        when 'select'
          scalersSelected = @items.selected() and @items.selected().scalersSelected
          if scalersSelected then @items.sacleSelected(event) else @items.translateSelected(event.delta)

          # redraw comment arrow if there is one.
          @comments.redrawArrow(@items.selected().commentMin) if @items.selected().commentMin

    onMouseUp: (canvas, event) ->
      event.point = @applyCurrentScale(event.point)
      tooltype = @opts.tooltype

      switch tooltype
        when 'line'
          @opts.tool.add(event.point)
          @opts.tool.simplify(10)
        when 'highligher'
          @opts.tool.add(event.point)
          @opts.tool.simplify(10)
        when "comment"
          commentRect = if @opts.tool and @opts.tool.isCommentRect then @opts.tool else null
          commentMin = @comments.create(event.point.x, event.point.y, commentRect)
          commentRect.commentMin = commentMin if commentRect

      switch tooltype
        when 'straightline', 'arrow', 'circle', 'rectangle', 'line', 'highligher'
          @opts.tool.eligible = true
          @history.add()

          @opts.tool.elementId = @generateId()
          @socket.emit("elementUpdate", @socketHelper.prepareElementToSend(@opts.tool))
        when "comment"
          if commentRect
            @opts.tool.eligible = true
            @history.add()
          else
            @history.add(type: "comment", commentMin: commentMin, eligible: true)

          commentMin.elementId = @generateId()
          @socket.emit("commentUpdate", @socketHelper.prepareCommentToSend(commentMin))
        when 'select'
          @socket.emit("elementUpdate", @socketHelper.prepareElementToSend(@items.selected())) if @items.selected()

      @opts.tooltype = "select" if tooltype == 'comment'

      @canvas.updateSelectedThumb()

    # Misc methods

    applyCurrentScale: (point) ->
      point.transform(new Matrix(1 / @opts.currentScale, 0, 0, 1 / @opts.currentScale, 0, 0))

    generateId: -> $("#uid").val() + new Date().getTime()

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
