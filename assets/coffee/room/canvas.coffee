$ ->
  class RoomCanvas

    # INITIALIZATION START

    init: ->
      @initElements()
      @initComments()
      @initThumbnails()

    initElements: ->
      selectedCid = @getSelectedCanvasId()
      @forEachThumbInContext (cid) ->
        canvasElements = []
        canvasElements.push(JSON.parse($(rawElement).val())) for rawElement in $(".canvasElement#{cid}")

        for element in canvasElements
          path = room.socketHelper.createElementFromData(element)

          unless cid is selectedCid
            room.helper.findById(path.id).remove()

          path.strokeColor = element.strokeColor
          path.strokeWidth = element.strokeWidth
          path.opacity = element.opacity

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
              room.comments.addTodo $("#commentText#{text.elementId}").clone()

    initThumbnails: ->
      selectedCid = @getSelectedCanvasId()

      @forEachThumbInContext (cid, fid) =>
        if fid
          @addImage fid, (raster, executeLoadImage) =>
            executeLoadImage()

            if cid isnt selectedCid and opts.image.id isnt raster.id
              room.helper.findById(raster.id).remove()

            @updateThumb(cid)
        else
          @updateThumb(cid)

    # executes function for each cavnvas in context of opts of this canvas
    forEachThumbInContext: (fn) ->
      selectedCid = @getSelectedCanvasId()
      for thumb in @getThumbs()
        cid = $(thumb).data("cid")
        fid = $(thumb).data("fid")
        opts = @findCanvasOptsById(cid)
        if opts then room.setOpts(opts) else room.initOpts(cid)

        fn(cid, fid)

      selectedOpts = @findCanvasOptsById(selectedCid)
      room.setOpts(selectedOpts)

    # INITIALIZATION END

    delete: ->
      if confirm "Are you sure? This will delete all canvas content."
        @clear true, true

    clear: (force, emit) ->
      room.history.add
        actionType: "clear", tools: room.history.getSelectableTools(), eligible: true
      for element in opts.historytools.allHistory
        element.opacity = 0 if (not element.actionType and not element.isImage) or force
        room.comments.hideComment(element.commentMin) if element.commentMin

      room.items.unselect()
      room.redrawWithThumb()

      selectedCanvasId = @getSelectedCanvasId()

      if force
        for element, index in opts.historytools.allHistory
          if element.isImage
            opts.historytools.allHistory.splice(index, 1)
            opts.image = null
            element.remove()
            break

        if @getThumbs().length > 1
          @getSelected().remove()
          @selectThumb($("#canvasSelectDiv a:first"))
          room.savedOpts.splice(room.savedOpts.indexOf(@findCanvasOptsById(selectedCanvasId)), 1)
          room.setOpts @findCanvasOptsById(@getSelectedCanvasId())

      if emit
        if force
          room.socket.emit "removeCanvas", canvasId: selectedCanvasId
        else
          room.socket.emit "eraseCanvas", canvasId: selectedCanvasId

    # used upon eraseCanvas event
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

    restore: (withComments)->
      for element in opts.historytools.allHistory
        unless element.actionType
          if element.isImage
            paper.project.activeLayer.insertChild(0, element)
          else
            paper.project.activeLayer.addChild(element)

        room.comments.showComment(element.commentMin) if element.commentMin and withComments

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
      img = @addImage fileId, (raster, executeLoadImage) =>
        executeLoadImage()

        @updateSelectedThumb(canvasId)

      room.socket.emit("fileAdded", {canvasId: canvasId, fileId: fileId}) if emit

    addImage: (fileId, loadWrap) ->
      src = "/files/#{$("#pid").val()}/#{fileId}"
      image = $("<img class='hide' src='#{src}'>")
      $("body").append(image)

      fakeImage = new Image()
      fakeImage.src = "/images/blank.jpg"

      img = new Raster(fakeImage)
      img.isImage = true
      paper.project.activeLayer.insertChild(0, img)
      img.fileId = fileId
      opts.image = img
      room.history.add(img)

      onload = ->
        img.size.width = image.width()
        img.size.height = image.height()
        img.position = paper.view.center
        img.setImage(image[0])

      $(image).on "load", -> if loadWrap then loadWrap(img, -> onload()) else onload()

      img

    addNewThumb: (canvasId) ->
      thumb = $("<a href='#' data-cid='#{canvasId}'><canvas width='80' height='60'></canvas></a>")
      $("#canvasSelectDiv").append(thumb)

    addNewThumbAndSelect: (canvasId) ->
      @erase()
      room.initOpts(canvasId)

      @addNewThumb(canvasId)

      $("#canvasSelectDiv a").removeClass("canvasSelected")
      $("#canvasSelectDiv a:last").addClass("canvasSelected")

    updateThumb: (canvasId)  ->
      selectedCanvasId = @getSelectedCanvasId()

      if selectedCanvasId isnt canvasId
        @activateCopyCanvas()
        prevOpts = room.getOpts()
        room.setOpts(@findCanvasOptsById(canvasId))
        @clearCopyCanvas()
        @restore(false)

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

      if prevOpts
        @activateNormalCanvas()
        room.setOpts(prevOpts)

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
      @restore(true)

      $(anchor).addClass("canvasSelected")

      room.socket.emit("switchCanvas", cid) if emit
      room.redraw()

    findCanvasOptsById: (canvasId) ->
      for savedOpt in room.savedOpts
        return savedOpt if savedOpt.canvasId is canvasId
      return null

  App.room.canvas = new RoomCanvas