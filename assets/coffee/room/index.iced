$ ->
  class Room
    constructor: ->
      @opts = {}
      @savedOpts = []
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

      $("#scaleDiv .dropdown-menu a").on "click", ->
        opts.scaleChanged = true
        scaleAmout = $(@).data('scale')
        if scaleAmout is "fitToImage"
          scaleAmout = App.room.canvas.getFitToImage()
        App.room.canvas.setScale scaleAmout

      @initDropbox()

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
      @comments.assignBringToFront()

      # disable canvas text selection for cursor change
      canvas = $("#myCanvas")[0]
      canvas.onselectstart = -> return false
      canvas.onmousedown = -> return false

      false

    initDropbox: ->
      $("#dropboxChoose").on "click", ->
        link = @
        if Dropbox?
          Dropbox.choose
            success: (files) ->
              $("#canvasInitButtons").fadeOut()
              $("#loadingProgressWrap").fadeIn()
              $("#loadingProgressWrap .bar").css("width", "100%")

              linkInfos = []
              for file in files
                linkInfo = link: file.link
                linkInfo.cid = App.room.canvas.getSelectedCanvasId() if not App.room.canvas.isFirstInitialized()
                linkInfos.push linkInfo

              posX = paper.view.center.x
              posY = paper.view.center.y
              $.post '/file/uploadDropbox', {pid: $("#pid").val(), linkInfos: linkInfos, posX: posX, posY: posY}, (data, status, xhr) =>
                $("#canvasInitButtons").show()
                $("#loadingProgressWrap").hide()

                for file in data
                  App.room.canvas.handleUpload
                    canvasId: file.canvasId
                    fileId: file.element.id
                    name: file.canvasName
                    posX: file.element.posX
                    posY: file.element.posY
                  , true
            cancel: -> console.log "cancel hit"
        else
          alert "Can't reach Dropbox API. Check your internet connection."

      script = $("<script type='text/javascript' src='https://www.dropbox.com/static/api/1/dropbox.js' id='dropbox' data-app-key='btskqrr7wnr3k20'></script>")
      $("body").append(script)

    initOpts: (canvasId) ->
      @opts = {}
      window.opts = @opts
      $.extend(@opts, @defaultOpts)
      @opts.historytools =
        eligibleHistory: []
        allHistory: []
      @opts.canvasId = canvasId
      @opts.scaledCenter = paper.view.center
      @savedOpts.push(@opts)

    setOpts: (opts) ->
      @opts = opts
      window.opts = opts

    getOpts: -> @opts

    # Mouse events handling

    onMouseMove: (canvas, event) ->
      event.point = @applyCurrentScale(event.point)
      canvas.css cursor: "default"
      rect = @items.sel?.selectionRect
      if rect
        scalers = rect.scalers
        for sc, scaler of scalers
          if scaler.bounds.contains(event.point)
            canvas.css cursor: "#{sc}-resize"
        if rect.removeButton and rect.removeButton.bounds.contains(event.point)
          canvas.css cursor: "pointer"

    onMouseDown: (canvas, event) ->
      event.point = @applyCurrentScale(event.point)

      $("#removeSelected").addClass("disabled")

      @items.sel?.selectionRect?.remove()

      @items.created = null

      switch @sharedOpts.tooltype
        when 'line'
          @items.init new Path()
        when 'highligher'
          @items.init new Path(), {color: @sharedOpts.color, width: 15, opacity: 0.7}
        when 'straightline'
          @items.init new Path()
          @items.created.add(event.point) for [0..1]
        when 'arrow'
          arrow = new Path()
          @items.init arrow
          @items.created.add(event.point) for [0..1]
          @items.created.lineStart = event.point
        when "select"
          @items.testSelect(event.point)
          @items.drawSelRect(event.point)

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
          @items.created.add(event.point)
          @items.created.smooth()
        when 'highligher'
          @items.created.add(event.point)
          @items.created.smooth()
        when 'circle'
          rectangle = new Rectangle(event.point.x, event.point.y, deltaPoint.x, deltaPoint.y)
          @items.init new Path.Oval(rectangle)
          @items.created.removeOnDrag()
        when 'rectangle'
          rectangle = new Rectangle(event.point.x, event.point.y, deltaPoint.x, deltaPoint.y)
          @items.init new Path.Rectangle(rectangle)
          @items.created.removeOnDrag()
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
          @items.init rectangle, styleObject
          @items.created.removeOnDrag()
        when 'straightline'
          @items.created.lastSegment.point = event.point
        when 'arrow'
          @items.created.lastSegment.point = event.point
          @items.drawArrow @items.created
          @items.created.arrowGroup.triangle.removeOnDrag()
        when 'pan'
          @items.pan event.delta
        when 'select'
          scalerSelected = @items.sel?.selectedScaler?
          if scalerSelected
            @items.sel.scaled = true
            @items.scale(event)
          else
            @items.translate(event.delta)

          # redraw comment arrow if there is one.
          @comments.redrawArrow(@items.sel.commentMin) if @items.sel?.commentMin

    onMouseUp: (canvas, event) ->
      event.point = @applyCurrentScale(event.point)
      tooltype = @sharedOpts.tooltype

      switch tooltype
        when 'line'
          @items.created.add(event.point)
          @items.created.simplify(64)
        when 'highligher'
          @items.created.add(event.point)
          @items.created.simplify(64)
        when "comment"
          commentRect = if @items.created and @items.created.isCommentRect then @items.created
          commentMin = @comments.create(event.point.x, event.point.y, commentRect)
          commentRect.commentMin = commentMin if commentRect

      switch tooltype
        when 'straightline', 'arrow', 'circle', 'rectangle', 'line', 'highligher'
          # Check if the item is empty then there is no need to save it on the server.
          unless @items.isEmpty @items.created
            @items.created.eligible = true
            @history.add()

            @items.created.elementId = @generateId()
            @socket.emit("elementUpdate", @socketHelper.prepareElementToSend(@items.created, "create"))
        when "comment"
          if commentRect
            @items.created.eligible = true
            @history.add()
          else
            @history.add actionType: "comment", commentMin: commentMin, eligible: true

          commentMin.elementId = @generateId()
          @socket.emit("commentUpdate", @socketHelper.prepareCommentToSend(commentMin, "create"))
        when 'select'
          selectedItem = @items.sel
          if selectedItem
            action = if selectedItem.scaled then "scale" else "move"
            selectedItem.scaled = null
            if selectedItem.commentMin # if the dragged element is comment rectangle
              @socket.emit "commentUpdate", @socketHelper.prepareCommentToSend(selectedItem.commentMin, action)
            else
              @socket.emit "elementUpdate", @socketHelper.prepareElementToSend(selectedItem, action)

      @sharedOpts.tooltype = "select" if tooltype is 'comment'

      @canvas.updateSelectedThumb()

    # Misc methods

    showSplashScreen: (showCancelLink = true) ->
      return if $("#canvasInitDivWrapper:visible")[0]

      $("#canvasInitDivWrapper").show()
      $("#myCanvas").hide()
      $("#commentsDiv").hide()
      $("#cancelInitLink").show() if showCancelLink

      App.chat.fold()
      App.room.canvas.foldPreviews()

    hideSplashScreen: () ->
      return unless $("#canvasInitDivWrapper:visible")[0]

      $("#canvasInitDivWrapper").hide()
      $("#myCanvas").show()
      $("#commentsDiv").show()

      App.chat.unfold()
      App.room.canvas.unfoldPreviews()

    applyCurrentScale: (point) ->
      point.transform(new Matrix(1 / @opts.currentScale, 0, 0, 1 / @opts.currentScale, 0, 0))

    applyReverseCurrentScale: (point) ->
      point.transform(new Matrix(@opts.currentScale, 0, 0, @opts.currentScale, 0, 0))

    generateId: -> $("#uid").val() + Date.now()

    redraw: ->
      paper.view.draw()

    redrawWithThumb: ->
      @redraw()
      @canvas.updateSelectedThumb()

  room = new Room
  $.extend(App.room, room)

$ ->
  return unless currentPage("projects/room/show")

  # initialize dropbox script
  # todo test
  $("body").append("<script type='text/javascript' src='https://www.dropbox.com/static/api/1/dropbox.js'
  id='dropboxjs' data-app-key='btskqrr7wnr3k20'></script>")

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
  newViewSize = Rectangle.create(0, 0, $("body").width(), $("body").height()).getSize()
  prj.view.setViewSize newViewSize for prj in paper.projects
