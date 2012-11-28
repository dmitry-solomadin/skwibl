$ ->
  class RoomCanvas

    # INITIALIZATION START

    init: ->
      @initElements()
      @initComments()
      @initThumbnails()

    initElements: ->
      removeElementById = (id) ->
        for element in paper.project.activeLayer.children # todo maybe should be changed to opts.historytools.allhistory
          element.remove() if element.id == id

      selectedCid = @getSelectedCanvasId()
      @forEachThumbInContext (cid) ->
        canvasElements = []
        canvasElements.push(JSON.parse($(rawElement).val())) for rawElement in $(".canvasElement#{cid}")

        for element in canvasElements
          path = room.socketHelper.createElementFromData(element)

          removeElementById(path.id) unless cid is selectedCid

          path.strokeColor = element.strokeColor
          path.strokeWidth = element.strokeWidth
          path.opacity = element.opacity

          path.eligible = false
          room.history.add(path)

    initComments: ->
      selectedCid = @getSelectedCanvasId()
      @forEachThumbInContext (cid) ->
        canvasComments = []
        canvasComments.push(JSON.parse($(rawComment).val())) for rawComment in $(".canvasComment#{cid}")

        for comment in canvasComments
          texts = JSON.parse($("#commentTexts#{comment.elementId}").val())

          createdComment = room.socketHelper.createCommentFromData(comment)
          room.comments.hideComment(createdComment) unless cid is selectedCid

          for text in texts
            room.comments.addCommentText createdComment, text.text, text.elementId

    # todo we should rewrite this part if possible, I don't like the idea of callbacks here
    initThumbnails: ->
      selectedCid = @getSelectedCanvasId()
      callback = (img, canvasId) =>
        prevOpts = room.getOpts()
        room.setOpts(@findCanvasOptsById(canvasId))

        #initialize thumbnails
        if selectedCid == canvasId
          paper.projects[1].activate()
        else
          paper.projects[0].activate()
        @updateThumb canvasId
        @clearCopyCanvas()
        @setImage(img)
        paper.projects[1].activate()

        room.setOpts(prevOpts)

      for thumb in @getThumbs()
        cid = $(thumb).data("cid")
        if selectedCid == cid
          paper.projects[1].activate()
        else
          paper.projects[0].activate()
        @addImage $(thumb).data("fid"), ((canvasId)->
          (img) -> callback(img, canvasId)
        )(cid)
        paper.projects[1].activate()


    # executes function for each cavnvas in context of opts of this canvas
    forEachThumbInContext: (fn) ->
      selectedCid = @getSelectedCanvasId()
      for thumb in @getThumbs()
        cid = $(thumb).data("cid")
        opts = @findCanvasOptsById(cid)
        if opts then room.setOpts(opts) else room.initOpts(cid)

        fn(cid)

      selectedOpts = @findCanvasOptsById(selectedCid)
      room.setOpts(selectedOpts)

    # INITIALIZATION END

    clear: ->
      room.history.add
        type: "clear", tools: room.history.getSelectableTools(), eligible: true
      for element in opts.historytools.allHistory
        element.opacity = 0 unless element.type
        room.comments.hideComment(element.commentMin) if element.commentMin

      room.items.unselect()
      room.redrawWithThumb()

      room.socket.emit("eraseCanvas")

    # used upon eraseCanvas event
    erase: ->
      for element in opts.historytools.allHistory
        console.log element
        element.remove() unless element.type
        room.comments.hideComment(element.commentMin) if element.commentMin

      room.redraw()

    clearCopyCanvas: ->
      child.remove() for child in paper.projects[0].activeLayer.children

    restore: ->
      for element in opts.historytools.allHistory
        unless element.type
          if element.isImage
            paper.project.activeLayer.insertChild(0, element)
          else
            paper.project.activeLayer.addChild(element)

        room.comments.showComment(element.commentMin) if element.commentMin

    setScale: (scale) ->
      finalScale = scale / opts.currentScale
      opts.currentScale = scale

      transformMatrix = new Matrix(finalScale, 0, 0, finalScale, 0, 0)

      paper.project.activeLayer.transform(transformMatrix)

      for element in opts.historytools.allHistory
        if element.commentMin
          element.commentMin.css({top: element.commentMin.position().top * finalScale,
          left: element.commentMin.position().left * finalScale})

          commentMax = element.commentMin[0].$maximized
          commentMax.css({top: commentMax.position().top * finalScale, left: commentMax.position().left * finalScale})

          room.comments.redrawArrow(element.commentMin)

      room.redraw()

    addScale: -> @setScale(opts.currentScale + 0.1);

    subtractScale: -> @setScale(opts.currentScale - 0.1);

    # CANVAS THUMBNAILS & IMAGE UPLOAD

    handleUpload: (canvasId, fileId, emit) ->
      @addNewThumbAndSelect(canvasId) if opts.image
      @addImage fileId, (img) =>
        @setImage(img)
        @updateSelectedThumb()
        room.socket.emit("fileAdded", {canvasId: canvasId, fileId: fileId}) if emit

    addImage: (fileId, callback) ->
      image = new Image()
      image.src = "/files/#{$("#pid").val()}/#{fileId}"

      activeProject = paper.project

      $(image).on "load", ->
        img = new Raster(image)
        img.isImage = true
        activeProject.activeLayer.insertChild(0, img)

        img.size.width = image.width
        img.size.height = image.height
        img.position = paper.view.center
        img.fileId = fileId

        callback(img) if callback?

    setImage: (img) ->
      opts.image = img

      room.history.add(img)

    addNewThumb: (canvasId) ->
      thumb = $("<a href='#' data-cid='#{canvasId}'><canvas width='80' height='60'></canvas></a>")
      $("#canvasSelectDiv").append(thumb)

    addNewThumbAndSelect: (canvasId) ->
      @erase()
      room.initOpts(canvasId)

      @addNewThumb(canvasId)

      $("#canvasSelectDiv a").removeClass("canvasSelected")
      $("#canvasSelectDiv a:last").addClass("canvasSelected")

    updateThumb: (canvasId) ->
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
      thumbContext.drawImage(canvas, shift, 0) for i in [0..5]

      transformMatrix = new Matrix(opts.currentScale / sy, 0, 0, opts.currentScale / sy, 0, 0)
      paper.project.activeLayer.transform(transformMatrix)
      room.redraw()

    updateSelectedThumb: -> @updateThumb @getSelectedCanvasId()

    getSelectedCanvasId: -> @getSelected().data("cid")

    getSelected: -> $(".canvasSelected")

    getThumbs: -> $("#canvasSelectDiv a")

    findThumbByCanvasId: (canvasId) -> $("#canvasSelectDiv a[data-cid='#{canvasId}']")

    selectThumb: (anchor, emit) ->
      return if $(anchor).hasClass("canvasSelected")

      $("#canvasSelectDiv a").removeClass("canvasSelected")

      cid = $(anchor).data("cid")
      canvasOpts = @findCanvasOptsById(cid)

      alert("No canvas opts by given canvasId=" + cid) unless canvasOpts

      @erase()
      room.setOpts(canvasOpts)
      @restore()

      $(anchor).addClass("canvasSelected")

      room.socket.emit("switchCanvas", cid) if emit
      room.redraw()

    findCanvasOptsById: (canvasId) ->
      for savedOpt in room.savedOpts
        return savedOpt if savedOpt.canvasId is canvasId
      return null

  App.room.canvas = new RoomCanvas