$ ->
  class Room
    constructor: ->
      @opts = {}
      @savedOpts = new Array
      @sharedOpts =
        tooltype: 'line'
        color: '#404040'

      @defaultOpts =
        defaultWidth: 2
        currentScale: 1
        opacity: 1
        pandx: 0
        pandy: 0

    init: (canvasId) ->
      @initOpts(canvasId)

      $(".toolTypeChanger").on "click", ->
        sharedOpts.tooltype = $(@).data("tooltype")

      $("#additionalInsSelect a").click ->
        $("#additionalInsDropdown").find("img").attr("src", $(@).find("img").attr("src"))
        $("#additionalInsDropdown").attr("data-tooltype", $(@).data("tooltype")).data("tooltype", $(@).data("tooltype"))
        $("#additionalInsDropdown").attr("data-original-title", $(@).data("title")).data("original-title", $(@).data("title"))

      $('#colorSelect .color').click ->
        $('#colorSelect .color').removeClass('activen')
        sharedOpts.color = $(@).attr('data-color')
        $(@).addClass('activen')

        $(".colorSelected").css("background", sharedOpts.color)

      $("#scaleDiv .dropdown-menu a").on "click", -> App.room.canvas.setScale($(@).data('scale'))

      @canvas.initNameChanger()

      $(document).on "click", "#canvasSelectDiv a", ->
        App.room.canvas.selectThumb(@, true)
        false

      $(document).on "mouseover", "#canvasSelectDiv div", ->
        App.room.canvas.onMouseOverThumb(@)
        false

      $(document).on "mouseout", "#canvasSelectDiv div", ->
        App.room.canvas.onMouseOutThumb(@)
        false

      $(document).on "click", ".smallCanvasPreview", ->
        App.room.canvas.selectMiniThumb(@, true)
        false

      @helper.initUploader()
      @helper.initHotkeys()
      @canvas.init()

      # disable canvas text selection for cursor change
      canvas = $("#myCanvas")[0]
      canvas.onselectstart = -> return false
      canvas.onmousedown = -> return false

      false

    initOpts: (canvasId) ->
      @opts = {}
      window.opts = @opts
      $.extend(@opts, @defaultOpts)
      @opts.historytools =
        eligibleHistory: new Array
        allHistory: new Array
      @opts.canvasId = canvasId
      @savedOpts.push(@opts)

    setOpts: (opts) ->
      @opts = opts
      window.opts = opts

    getOpts: -> @opts

    # Mouse events handling

    onMouseMove: (canvas, event) ->
      event.point = @applyCurrentScale(event.point)

      canvas.css({cursor: "default"})

      selectedTool = @items.selected()
      if selectedTool?.selectionRect?
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

      switch @sharedOpts.tooltype
        when 'line'
          @items.create(new Path())
        when 'highligher'
          @items.create(new Path(), {color: @sharedOpts.color, width: 15, opacity: 0.7})
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

      switch @sharedOpts.tooltype
        when 'line', 'highligher', 'arrow', 'circle', 'rectangle', 'comment', 'straightline'
          @socket.emit "userMouseDown", x: event.point.x - opts.pandx, y: event.point.y - opts.pandy

    onMouseDrag: (canvas, event) ->
      event.point = @applyCurrentScale(event.point)
      event.delta = @applyCurrentScale(event.delta)
      event.downPoint = @applyCurrentScale(event.downPoint)

      deltaPoint = event.downPoint.subtract(event.point)

      switch @sharedOpts.tooltype
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
          styleObject = $.extend({}, @comments.COMMENT_RECT_DEFAULT_STYLE)
          @items.create(rectangle, styleObject)
          @opts.tool.removeOnDrag()
        when 'straightline'
          @opts.tool.lastSegment.point = event.point
        when 'arrow'
          arrowLine = @opts.tool.arrow
          arrowLine.lastSegment.point = event.point

          arrowGroup = @items.drawArrow(arrowLine)

          @opts.tool = arrowGroup
          arrowGroup.triangle.removeOnDrag()
        when 'pan'
          @items.pan(event.delta.x, event.delta.y)
        when 'select'
          scalersSelected = @items.selected()?.scalersSelected
          if scalersSelected then @items.sacleSelected(event) else @items.translateSelected(event.delta)

          # redraw comment arrow if there is one.
          @comments.redrawArrow(@items.selected().commentMin) if @items.selected().commentMin

    onMouseUp: (canvas, event) ->
      event.point = @applyCurrentScale(event.point)
      tooltype = @sharedOpts.tooltype

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
          # Check if the item is empty then there is no need to save it on the server.
          unless @items.isItemEmpty(@opts.tool)
            @opts.tool.eligible = true
            @history.add()

            @opts.tool.elementId = @generateId()
            @socket.emit("elementUpdate", @socketHelper.prepareElementToSend(@opts.tool))
        when "comment"
          if commentRect
            @opts.tool.eligible = true
            @history.add()
          else
            @history.add(actionType: "comment", commentMin: commentMin, eligible: true)

          commentMin.elementId = @generateId()
          @socket.emit("commentUpdate", @socketHelper.prepareCommentToSend(commentMin))
        when 'select'
          selectedItem = @items.selected()
          if selectedItem
            if selectedItem.commentMin # if the dragged element is comment rectangle
              @socket.emit "commentUpdate", @socketHelper.prepareCommentToSend(selectedItem.commentMin)
            else
              @socket.emit "elementUpdate", @socketHelper.prepareElementToSend(selectedItem)

      @sharedOpts.tooltype = "select" if tooltype == 'comment'

      @canvas.updateSelectedThumb()

    # Misc methods

    applyCurrentScale: (point) ->
      point.transform(new Matrix(1 / @opts.currentScale, 0, 0, 1 / @opts.currentScale, 0, 0))

    applyReverseCurrentScale: (point) ->
      point.transform(new Matrix(@opts.currentScale, 0, 0, @opts.currentScale, 0, 0))

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

  paper.setup($('#copyCanvas')[0]);
  paper.setup($('#myCanvas')[0]);

  # initilazing events
  tool = new paper.Tool()
  tool.onMouseDown = (event) -> App.room.onMouseDown($("#myCanvas"), event)
  tool.onMouseDrag = (event) -> App.room.onMouseDrag($("#myCanvas"), event)
  tool.onMouseUp = (event) -> App.room.onMouseUp($("#myCanvas"), event)
  tool.onMouseMove = (event) -> App.room.onMouseMove($("#myCanvas"), event)

  window.room = App.room
  window.opts = App.room.opts
  window.sharedOpts = App.room.sharedOpts

  App.room.init(App.room.canvas.getSelectedCanvasId())

  # resizing canvas
  paper.view.setViewSize(Rectangle.create(0, 0, $("body").width(), $("body").height()).getSize())