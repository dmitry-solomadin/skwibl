$ ->
  class RoomCanvas

  # INITIALIZATION START

    init: ->
      @initElements()
      @initComments()
      @initThumbnails()

    #@initBackground()

    initElements: ->
      selectedCid = @getSelectedCanvasId()
      @forEachThumbInContext (cid) ->
        canvasElements = []
        canvasElements.push(JSON.parse($(rawElement).val())) for rawElement in $(".canvasElement#{cid}")

        for element in canvasElements
          path = room.socketHelper.createElementFromData(element)

          unless cid is selectedCid
            room.helper.findById(path.id).remove()

          room.items.init path,
            color: element.strokeColor
            width: element.strokeWidth
            opacity: element.opacity
            noBuffer: true

          path.eligible = false
          room.history.add(path)

        room.redraw()

    initComments: ->
      selectedCid = @getSelectedCanvasId()
      @forEachThumbInContext (cid) ->
        canvasComments = []
        canvasComments.push(JSON.parse($(rawComment).val())) for rawComment in $(".canvasComment#{cid}")

        for comment in canvasComments
          texts = []
          texts.push(JSON.parse($(rawText).val())) for rawText in $(".commentTexts#{comment.elementId}")

          createdComment = room.socketHelper.createCommentFromData(comment)
          unless cid is selectedCid
            room.comments.hideComment(createdComment)

          for text in texts
            room.comments.addCommentText createdComment, text
            if text.todo
              room.comments.addTodo $("#commentText#{text.elementId}")

    initThumbnails: ->
      selectedCid = @getSelectedCanvasId()

      isAnyFilePresent = false
      for thumb in @getThumbs()
        if $(thumb).data("fid")
          isAnyFilePresent = true
          break

      @forEachThumbInContext (cid, fid, posX, posY, index) =>
        if fid
          @addImage fid, posX, posY, (raster, executeLoadImage) =>
            executeLoadImage()

            if cid isnt selectedCid and opts.image and opts.image.id isnt raster.id
              room.helper.findById(raster.id).remove()

            @updateThumb(cid)
            if (room.canvas.getThumbs().length - 1) is index
              @onLoadingFinished()
        else
          @onLoadingFinished() unless isAnyFilePresent

          @updateThumb(cid)

    initBackground: ->
      wFreq = 25
      wCount = Math.ceil($("#myCanvas").width() / wFreq)
      hFreq = 25
      hCount = Math.ceil($("#myCanvas").height() / hFreq)
      each = 3

      background = new Group()

      createItem = (index, vertical) ->
        path = new Path()
        path.strokeColor = "#c7c7c7"
        path.opacity = if index % each is 0 then "0.26" else "0.12"
        path.strokeWidth = "1"
        if vertical
          startX = wFreq * index
          path.add new Point(startX, 0)
          path.add new Point(startX, $("#myCanvas").height())
        else
          startY = hFreq * index
          path.add new Point(0, startY)
          path.add new Point($("#myCanvas").width(), startY)
        background.addChild(path)

      createItem index, true for index in [1..wCount]
      createItem index, false for index in [1..hCount]

      paper.project.activeLayer.insertChild(0, background)

    # executes function for each cavnvas in context of opts of this canvas
    forEachThumbInContext: (fn) ->
      selectedCid = @getSelectedCanvasId()
      for thumb, index in @getThumbs()
        cid = $(thumb).data("cid")
        fid = $(thumb).data("fid")
        posX = $(thumb).data("pos-x")
        posY = $(thumb).data("pos-y")
        opts = @findOptsById(cid)
        if opts then room.setOpts(opts) else room.initOpts(cid)

        fn cid, fid, posX, posY, index

      selectedOpts = @findOptsById(selectedCid)
      room.setOpts(selectedOpts)

    onLoadingFinished: ->
      # highlight to-do if id is provided
      if window.location.hash
        commentTextIdRaw = window.location.hash.match(/tsl=(\d+)/)
        if commentTextIdRaw
          commentTextId = commentTextIdRaw[1]
          room.comments.highlightComment commentTextId, true

        canvasIdRaw = window.location.hash.match(/cid=(\d+)/)
        if canvasIdRaw
          canvasId = canvasIdRaw[1]
          room.canvas.findThumbByCanvasId(canvasId).click()


      @centerOnImage()
      room.redraw()

    initNameChanger: ->
      $("#canvasName").on "click", ->
        $("#canvasName").hide()
        $("#canvasNameInputDiv").show()

        if $("#canvasName").hasClass("noname")
          name = ""
        else
          name = $.trim($("#canvasName").html())

        $("#canvasNameInput").val(name).focus()

      $("#canvasNameSave").on "click", =>
        $("#canvasName").show()
        $("#canvasNameInputDiv").hide()

        name = $("#canvasNameInput").val()
        @changeName name

        room.socket.emit "changeCanvasName", canvasId: @getSelectedCanvasId(), name: name

    # INITIALIZATION END

    changeName: (name) ->
      if $.trim(name).length > 0
        $("#canvasName").removeClass("noname")
        $("#canvasName").html(name)
      else
        $("#canvasName").addClass("noname")
        $("#canvasName").html("blank name")

    onDeleteClick: (deleteLink) ->
      if confirm "Are you sure? This will delete all canvas content."
        cid = $(deleteLink).parent().find("a").data("cid")
        @destroy cid, true

    destroy: (cid, emit) ->
      optsToRemove = @findOptsById(cid)

      if @getThumbs().length > 1
        @findThumbByCanvasId(cid).parent().remove()
        @findMiniThumbByCanvasId(cid).remove()
        @selectThumb $("#canvasSelectDiv div:first a")
        room.savedOpts.splice room.savedOpts.indexOf(optsToRemove), 1
        room.setOpts @findOptsById(@getSelectedCanvasId())
      else
        @erase()
        room.savedOpts = []
        @deinitializeFirst()

      room.socket.emit "removeCanvas", canvasId: cid if emit

    #hides elements and emits canvas cleared event
    clear: (emit) ->
      room.history.add actionType: "clear", tools: room.history.getSelectableTools(), eligible: true if emit
      for element in opts.historytools.allHistory
        element.opacity = 0 if not element.actionType and not element.isImage
        room.comments.hideComment(element.commentMin) if element.commentMin

      room.items.unselect()
      room.redrawWithThumb()

      room.socket.emit "eraseCanvas", canvasId: @getSelectedCanvasId() if emit

    #removes elements for inner purposes
    erase: ->
      for element in opts.historytools.allHistory
        element.remove() unless element.actionType
        room.comments.hideComment(element.commentMin) if element.commentMin

      room.redraw()

    clearCopyCanvas: ->
      itemsToRemove = []
      itemsToRemove.push(child) for child in paper.projects[0].activeLayer.children
      item.remove() for item in itemsToRemove

    activateCopyCanvas: -> paper.projects[0].activate()

    activateNormalCanvas: -> paper.projects[1].activate()

    flushCanvasIntoCopy: (cid) ->
      @activateCopyCanvas()
      prevOpts = room.getOpts()
      room.setOpts(@findOptsById(cid))
      @clearCopyCanvas()
      @restore(false, true)
      room.redraw()
      @activateNormalCanvas()
      room.setOpts(prevOpts)

    restore: (withComments, clone)->
      for element in opts.historytools.allHistory
        unless element.actionType
          element = element.clone() if clone
          if element.isImage
            room.items.insertFirst(element)
          else
            paper.project.activeLayer.addChild(element)

        room.comments.showComment(element.commentMin) if element.commentMin and withComments

    getFitToImage: ->
      w = paper.project.view.viewSize.width / opts.image.width
      h = paper.project.view.viewSize.height / opts.image.height
      if h < w then h else w

    setScale: (scale, prevScale) ->
      $("#scaleAmount").html "#{parseInt(scale * 100)}%"

      previousScale = prevScale or opts.currentScale

      finalScale = scale / previousScale
      opts.currentScale = scale

      transformMatrix = new Matrix(finalScale, 0, 0, finalScale, 0, 0)
      paper.project.activeLayer.transform(transformMatrix)

      unless prevScale
        for element in opts.historytools.allHistory
          if element.commentMin
            element.commentMin.css({top: element.commentMin.position().top * finalScale,
            left: element.commentMin.position().left * finalScale})

            commentMax = element.commentMin[0].$maximized
            commentMax.css({top: commentMax.position().top * finalScale, left: commentMax.position().left * finalScale})

            room.comments.redrawArrow(element.commentMin)

      scaledCenter = opts.scaledCenter or paper.view.center
      newScaledCenter = room.applyCurrentScale paper.view.center
      opts.scaledCenter = newScaledCenter
      room.items.pan new Point(newScaledCenter.x - scaledCenter.x, newScaledCenter.y - scaledCenter.y)

      room.redraw()

    download: (downloadLink) ->
      cid = $(downloadLink).parent().find("a").data("cid")
      @flushCanvasIntoCopy cid

      dataURL = $("#copyCanvas")[0].toDataURL("image/png")
      $.post '/projects/prepareDownload', {pid: $("#pid").val(), canvasData: dataURL}, (data, status, xhr) =>
        window.location = "/projects/download?pid=#{$("#pid").val()}&img=#{data}"

    addScale: -> @setScale(opts.currentScale + 0.1);

    subtractScale: -> @setScale(opts.currentScale - 0.1);

    getViewportAdjustX: -> if App.chat.isVisible() then 300 else 0

    getViewportAdjustY: -> $("#canvasFooter").height()

    getViewportSize: ->
      w: $("#myCanvas").width() - @getViewportAdjustX()
      h: $("#myCanvas").height() - @getViewportAdjustY()

    # CANVAS THUMBNAILS & IMAGE UPLOAD

    onMouseOverThumb: (thumb) ->
      $(thumb).find(".canvasRemoveImg, .canvasDownloadImg, .canvasReorderImg").show()

    onMouseOutThumb: (thumb) ->
      $(thumb).find(".canvasRemoveImg, .canvasDownloadImg, .canvasReorderImg").hide()

    foldPreviews: ->
      $("#canvasFolder").addClass("canvasFolderTrans")
      $("#canvasFooter").animate {height: 37}, queue: false, complete: ->
        $("#canvasFolder").removeClass("canvasFolderTrans").find("img").attr("src", "/images/room/unfold-up.png")

      if $("#smallCanvasPreviewsWrap").css('position') is "relative"
        $("#nameChanger").animate(left: 0, 500)
      else
        $("#nameChanger").animate(left: $("#smallCanvasPreviews").outerWidth(true) + 20, 500)

      $("#smallCanvasPreviews").animate(left: 0, 500, 'linear')
      $("#canvasFolder").attr("onclick", "App.room.canvas.unfoldPreviews(this); return false;")

    unfoldPreviews: ->
      $("#canvasFolder").addClass("canvasFolderTrans")

      if $("#smallCanvasPreviewsWrap").css('position') is "relative"
        $("#nameChanger").animate(left: -$("#nameChanger").position().left, 500)
      else
        $("#nameChanger").animate(left: 0, 500)

      $("#canvasFooter").animate {height: 108}, duration: 500, easing: 'easeOutBack', queue: false, complete: ->
        $("#canvasFolder").removeClass("canvasFolderTrans").find("img").attr("src", "/images/room/fold-down.png")

      $("#smallCanvasPreviews").animate(left: -500, 500)
      $("#canvasFolder").attr("onclick", "App.room.canvas.foldPreviews(this); return false;")

    requestAddEmpty: ->
      thumbs = @getThumbs()
      initializeFirst = thumbs.length is 1 and not @isFirstInitialized()

      if initializeFirst
        $.post "/canvases/initializeFirst", {pid: $("#pid").val()}, (data, status, xhr) =>
          @initializeFirst true
      else
        $.post "/canvases/addEmpty", {pid: $("#pid").val()}, (data, status, xhr) =>
          @addEmpty canvasId: data.id, name: data.name, true

    initializeFirst: (emit) ->
      @erase()
      firstThumb = $(@getThumbs()[0])
      room.hideSplashScreen()
      firstThumb.attr("data-initialized", "true").data("initialized", "true")
      room.socket.emit "initializeFirstCanvas" if emit

    deinitializeFirst: () ->
      firstThumb = $(@getThumbs()[0])
      room.showSplashScreen()
      room.initOpts firstThumb.data("cid")
      #initialiaze new empty opts
      firstThumb.attr("data-initialized", "false").data("initialized", "false")

    addEmpty: (canvasData) ->
      @addNewThumbAndSelect canvasData
      room.hideSplashScreen()
      room.socket.emit "canvasAdded", canvasData

    handleUpload: (canvasData, emit) ->
      if @isFirstInitialized()
        room.hideSplashScreen true
        @addNewThumbAndSelect canvasData
      else
        @initializeFirst false

      @addImage canvasData.fileId, canvasData.posX, canvasData.posY, (raster, executeLoadImage) =>
        executeLoadImage()

        @updateThumb parseInt(canvasData.canvasId)

      room.socket.emit("fileAdded", canvasData) if emit

    addImage: (fileId, posX, posY, loadWrap) ->
      src = "/files/#{$("#pid").val()}/#{fileId}"
      image = $("<img class='hide' src='#{src}'>")
      $("body").append(image)

      fakeImage = new Image()
      fakeImage.src = "/images/blank.jpg"

      img = new Raster(fakeImage)
      img.isImage = true
      room.items.insertFirst(img)
      img.fileId = fileId
      opts.image = img
      room.history.add(img)

      onload = ->
        img.size.width = image.width()
        img.size.height = image.height()
        img.position = new Point parseInt(posX), parseInt(posY)
        img.setImage(image[0])

      $(image).on "load", -> if loadWrap then loadWrap(img, -> onload()) else onload()

      img

    centerOnImage: ->
      # do not center user if the moved the canvas by himself
      if opts.image and not opts.pandx and not opts.pandy
        centerX = paper.view.center.x
        centerY = paper.view.center.y
        imageX = opts.image.position.x
        imageY = opts.image.position.y

        if centerX isnt imageX or centerY isnt imageY
          room.items.pan new Point(centerX - imageX, centerY - imageY)

    addNewThumb: (canvasData) ->
      thumb = $("#canvasSelectDiv div:first").clone()
      thumb.find("a").attr("data-cid", canvasData.canvasId).attr("data-fid", canvasData.fileId)
        .attr("data-name", canvasData.name).attr("data-pos-x", canvasData.posX).attr("data-pos-y", canvasData.posY)
      $("#canvasSelectDiv").append(thumb)

    addNewMiniThumb: (canvasData) ->
      mini = $("<div class='smallCanvasPreview tooltipize' title='#{canvasData.name}'></div>")
      mini.attr("data-cid", canvasData.canvasId).attr("data-fid", canvasData.fileId).attr("data-name", canvasData.name)
      $("#smallCanvasPreviews").append(mini)

    addNewThumbAndSelect: (canvasData) ->
      @erase()
      room.initOpts(canvasData.canvasId)

      @addNewThumb canvasData
      @addNewMiniThumb canvasData

      $("#canvasSelectDiv a").removeClass("canvasSelected")
      $("#canvasSelectDiv div:last a").addClass("canvasSelected")
      $(".smallCanvasPreview").removeClass("previewSelected")
      $(".smallCanvasPreview:last").addClass("previewSelected")
      $("#canvasName").html(canvasData.name)

    updateThumb: (canvasId) ->
      selectedCanvasId = @getSelectedCanvasId()

      if selectedCanvasId isnt canvasId
        @activateCopyCanvas()
        prevOpts = room.getOpts()
        room.setOpts @findOptsById(canvasId)
        @clearCopyCanvas()
        @restore(false, false)
      else
        prevPandx = opts.pandx
        prevPandy = opts.pandy
        @centerOnImage true

      thumb = @findThumbByCanvasId(canvasId).find("canvas")
      thumbContext = thumb[0].getContext('2d')

      canvas = paper.project.view.element

      cvw = $(canvas).width()
      cvh = $(canvas).height()
      tw = $(thumb).width()
      th = $(thumb).height()
      sy = th / cvh

      transformMatrix = new Matrix(sy / opts.currentScale, 0, 0, sy / opts.currentScale, 0, 0)
      paper.project.activeLayer.transform(transformMatrix)
      room.redraw()

      shift = -((sy * cvw) - tw) / 2

      thumbContext.clearRect(0, 0, tw, th)
      thumbContext.drawImage(canvas, shift, 0) for i in [0..2]

      transformMatrix = new Matrix(opts.currentScale / sy, 0, 0, opts.currentScale / sy, 0, 0)
      paper.project.activeLayer.transform(transformMatrix)

      if selectedCanvasId is canvasId
        room.items.pan new Point(prevPandx - opts.pandx, prevPandy - opts.pandy)

      room.redraw()

      if prevOpts
        @activateNormalCanvas()
        room.setOpts(prevOpts)

    updateSelectedThumb: -> @updateThumb @getSelectedCanvasId()

    getSelectedCanvasId: -> @getSelected().data("cid")

    isFirstInitialized: -> "#{$(@getThumbs()[0]).data("initialized")}" == "true"

    getSelected: -> $(".canvasSelected")

    getMiniSelected: -> $("#smallCanvasPreviews .previewSelected")

    getThumbs: -> $("#canvasSelectDiv > div > a")

    findThumbByCanvasId: (canvasId) -> $("#canvasSelectDiv a[data-cid='#{canvasId}']")

    findMiniThumbByCanvasId: (canvasId) -> $(".smallCanvasPreview[data-cid='#{canvasId}']")

    selectMiniThumb: (mini, emit) ->
      cid = $(mini).data("cid")
      $(".smallCanvasPreview").removeClass("previewSelected")
      $(mini).addClass("previewSelected")
      @selectThumb @findThumbByCanvasId(cid), emit

    selectThumb: (anchor, emit) ->
      return if $(anchor).hasClass("canvasSelected")

      $("#canvasSelectDiv a").removeClass("canvasSelected")
      $(anchor).addClass("canvasSelected")

      cid = $(anchor).data("cid")
      canvasOpts = @findOptsById(cid)

      alert("No canvas opts by given canvasId=" + cid) unless canvasOpts

      @erase()
      room.items.unselect()
      previousScale = opts.currentScale
      room.setOpts canvasOpts
      @restore(true, false)
      @setScale opts.currentScale, previousScale

      $(".smallCanvasPreview").removeClass("previewSelected")
      $(@findMiniThumbByCanvasId(cid)).addClass("previewSelected")

      $("#canvasName").html($(anchor).data("name"))

      @centerOnImage()

      room.socket.emit("switchCanvas", cid) if emit
      room.redraw()

    findOptsById: (canvasId) -> return savedOpt for savedOpt in room.savedOpts when savedOpt.canvasId is canvasId

  App.room.canvas = new RoomCanvas
