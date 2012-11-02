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

    handleUpload: (image) ->
      @addNewThumb() if opts.image
      @addImage(image)
      @updateSelectedThumb()

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
      @erase()

      room.initOpts()

      $("#canvasSelectDiv a").removeClass("canvasSelected");
      $("#canvasSelectDiv").append("<a href='#' class='canvasSelected'><canvas width='80' height='60'></canvas></a>")

    updateSelectedThumb: ->
      selectedCanvas = $(".canvasSelected canvas")
      selectedContext = selectedCanvas[0].getContext('2d')
      canvas = paper.project.view.element
      cvw = $(canvas).width()
      cvh = $(canvas).height()
      scw = $(selectedCanvas).width()
      sch = $(selectedCanvas).height()
      sy = sch / cvh;

      transformMatrix = new Matrix(sy / opts.currentScale, 0, 0, sy / opts.currentScale, 0, 0)
      paper.project.activeLayer.transform(transformMatrix)
      room.redraw()

      shift = -((sy * cvw) - scw) / 2

      selectedContext.clearRect(0, 0, scw, sch);
      selectedContext.drawImage(canvas, shift, 0) for i in [0..5]

      transformMatrix = new Matrix(opts.currentScale / sy, 0, 0, opts.currentScale / sy, 0, 0)
      paper.project.activeLayer.transform(transformMatrix)
      room.redraw()

    selectThumb: (anchor) ->
      return if $(anchor).hasClass("canvasSelected")

      $("#canvasSelectDiv a").removeClass("canvasSelected")

      index = $(anchor).index();
      canvasOpts = @findCanvasOptsByIndex(index)

      alert("No canvas opts by given index=" + index) unless canvasOpts

      @erase();
      room.setOpts(canvasOpts)
      @restore();

      $(anchor).addClass("canvasSelected");

    findCanvasOptsByIndex: (index) ->
      for savedOpt, i in room.savedOpts
        return savedOpt if index == i
      return null

  App.room.canvas = new RoomCanvas