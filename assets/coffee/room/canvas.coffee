$ ->
  class RoomCanvas

    init: ->
      selectedCid = @getSelectedCanvasId()
      for thumb in @getThumbs()
        callback = (canvasId) =>
          opts = @findCanvasOptsById(canvasId)
          if opts then room.setOpts(opts) else room.initOpts(canvasId)

          if selectedCid == canvasId
            paper.projects[1].activate()
          else
            paper.projects[0].activate()
          @updateThumb canvasId
          @clearCopyCanvas()
          paper.projects[1].activate()

        cid = $(thumb).data("cid")
        if selectedCid == cid
          paper.projects[1].activate()
        else
          paper.projects[0].activate()
        @addImage $(thumb).data("fid"), ((canvasId)->
          -> callback(canvasId)
        )(cid)
        paper.projects[1].activate()
      initialOpts = @findCanvasOptsById(selectedCid)
      room.setOpts(initialOpts)

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
        element.remove() unless element.type
        room.comments.hideComment(element.commentMin) if element.commentMin

      room.redraw()

    eraseCompletely: ->
      for child in paper.project.activeLayer.children
        child.remove() if child
      room.redraw()

    clearCopyCanvas: ->
      child.remove() for child in paper.projects[0].activeLayer.children

    restore: ->
      for element in opts.historytools.allHistory
        paper.project.activeLayer.addChild(element) unless this.type
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
      @addNewThumbAndSelect(canvasId) if opts.fileId
      @addImage fileId, =>
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

        callback() if callback?

        opts.fileId = fileId
        opts.image = img

        room.history.add(img)

    addNewThumb: (canvasId) ->
      thumb = $("<a href='#' data-cid='#{canvasId}'><canvas width='80' height='60'></canvas></a>")
      $("#canvasSelectDiv").append(thumb)

    addNewThumbAndSelect: (canvasId) ->
      @eraseCompletely()
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

      @eraseCompletely()
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