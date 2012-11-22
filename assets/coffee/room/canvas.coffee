$ ->
  class RoomCanvas

    clear: ->
      room.history.add
        type: "clear", tools: room.history.getSelectableTools(), eligible: true
      for element in opts.historytools.allHistory
        element.opacity = 0 unless element.type
        room.comments.hideComment(element.commentMin) if element.commentMin

      room.items.unselect()
      room.redrawWithThumb()

      room.socket.emit("eraseCanvas")

    erase: ->
      for element in opts.historytools.allHistory
        element.remove() unless element.type
        room.comments.hideComment(element.commentMin) if element.commentMin

      room.redraw()

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

    handleUpload: (imagePath, emit) ->
      image = new Image()
      image.src = imagePath
      $(image).on "load", =>
        if opts.image
          @addNewThumbAndSelect()
        @addImage(image)
        @updateSelectedThumb()

        room.socket.emit("fileAdded", imagePath) if emit

    addImage: (image) ->
      img = new Raster(image)
      img.isImage = true
      paper.project.activeLayer.insertChild(0, img)

      img.size.width = image.width
      img.size.height = image.height
      img.position = paper.view.center

      opts.image = image

      room.history.add(img)

    addNewThumb: ->
      thumb = $("<a href='#'><canvas width='80' height='60'></canvas></a>")
      $("#canvasSelectDiv").append(thumb)

    addNewThumbAndSelect: ->
      @erase()
      room.initOpts()

      @addNewThumb()

      $("#canvasSelectDiv a").removeClass("canvasSelected")
      $("#canvasSelectDiv a:last").addClass("canvasSelected")

    updateThumb: (canvasIndex) ->
      thumb = $("#canvasSelectDiv a:eq(#{canvasIndex}) canvas")
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

    updateSelectedThumb: -> @updateThumb @selectedThumbCanvasIndex()

    selectedThumbCanvasIndex: -> @getSelected.index()

    getSelected: -> $(".canvasSelected")

    selectThumbByCanvasIndex: (canvasIndex, emit) ->
      @selectThumb($("#canvasSelectDiv a:eq(#{canvasIndex})"), emit)

    selectThumb: (anchor, emit) ->
      return if $(anchor).hasClass("canvasSelected")

      $("#canvasSelectDiv a").removeClass("canvasSelected")

      index = $(anchor).index()
      canvasOpts = @findCanvasOptsByIndex(index)

      alert("No canvas opts by given index=" + index) unless canvasOpts

      @erase()
      room.setOpts(canvasOpts)
      @restore()

      $(anchor).addClass("canvasSelected")

      room.socket.emit("switchCanvas", $(anchor).index()) if emit
      room.redraw()

    findCanvasOptsByIndex: (index) ->
      for savedOpt, i in room.savedOpts
        return savedOpt if index == i
      return null

  App.room.canvas = new RoomCanvas