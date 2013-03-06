$ ->
  class RoomCanvas

  # INITIALIZATION START

    init: ->
      @initElements()
      @initComments()
      @initThumbnails()
      @initThumbSort()
      @initCarousel()

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

    initThumbnails: ->
      selectedCid = @getSelectedCanvasId()

      isAnyFilePresent = false
      for thumb in @getThumbs()
        if $(thumb).data("fid")
          isAnyFilePresent = true
          break

      totalCanvases = room.canvas.getThumbs().length
      loadedCanvases = 0

      @forEachThumbInContext (cid, fid, posX, posY, index) =>
        if fid
          return @addImage fid, posX, posY, (raster, executeLoadImage) =>
            loadedCanvases++
            executeLoadImage()

            if cid isnt selectedCid and ((opts.image and opts.image.id isnt raster.id) or !opts.image)
              room.helper.findById(raster.id).remove()

            @onEachCanvasLoaded()
            @onFirstCavasLoaded() if index is 0
            @onLoadingFinished() if totalCanvases is loadedCanvases
            @updateThumb(cid)
        else
          loadedCanvases++
          @onEachCanvasLoaded()
          @onLoadingFinished() if totalCanvases is loadedCanvases
          @updateThumb(cid)

    initThumbSort: ->
      $("#canvasSelectDiv").sortable
        items: "> .canvasPreviewDiv"
        handle: ".gallery_slide_drag"
        distance: 10
        revert: true
        scroll: false
        update: (event, ui) ->
          cid = $(ui.item[0]).find(".clink").data("cid")
          pos = $(".canvasPreviewDiv").index(ui.item)
          room.socket.emit "canvasReorder", canvasId: cid, position: pos

    initCarousel: ->
      new App.SkwiblCarousel
        selector: '#canvasSelectDiv'
        height: 75
        adjustPaddings: true
        leftArrowClass: "gallery_l"
        rightArrowClass: "gallery_r"

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

    onFirstCavasLoaded: ->
      @setScale @getFitToImage()
      @centerOnImage()

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

      room.redraw()

    onEachCanvasLoaded: ->
      @changeCanvasBg()

    changeCanvasBg: ->
      canvas = $("#mainCanvas")
      if opts.image
        unless canvas.hasClass "canvasWrapper"
          canvas.addClass "canvasWrapper"
      else if canvas.hasClass "canvasWrapper"
        canvas.removeClass "canvasWrapper"

    initNameChanger: ->
      changeName = =>
        $("#canvasName").show()
        $("#canvasNameInputDiv").hide()
        name = $("#canvasNameInput").val()
        @changeName @getSelectedCanvasId(), name
        room.socket.emit "changeCanvasName", canvasId: @getSelectedCanvasId(), name: name

      cancelChangeName = =>
        $("#canvasName").show()
        $("#canvasNameInputDiv").hide()

      $("#canvasName").on "click", =>
        $("#canvasName").hide()
        $("#canvasNameInputDiv").show()

        if $("#canvasName").hasClass("noname")
          name = ""
        else
          name = $.trim($("#canvasName").html())

        $("#canvasNameInput").val(name).focus()

        $(document).on "click.changeName", (e) =>
          return if $(e.target).parents("#nameChanger")[0]
          changeName()
          $(document).off "click.changeName"

      $("#canvasNameInput").bind 'keydown.esc', => cancelChangeName()
      $("#canvasNameInput").bind 'keydown.return', => changeName()


    # INITIALIZATION END

    changeName: (cid, name) ->
      @findThumbByCanvasId(cid).data("name", name)
      @changeNameHtml name

    changeNameHtml: (name) ->
      if $.trim(name).length > 0
        $("#canvasName").removeClass("noname")
        $("#canvasName").html(name)
      else
        $("#canvasName").addClass("noname")
        $("#canvasName").html("blank name")

    onDeleteClick: (deleteLink) ->
      if confirm "Are you sure? This will delete all canvas content."
        cid = $(deleteLink).parent().find(".clink").data("cid")
        @destroy cid, true

    destroy: (cid, emit) ->
      if @getThumbs().length > 1
        canvasToRemove = @findThumbByCanvasId(cid).parent()
        canvasToRemove.animate {width: 0, opacity:0}, "slow", =>
          canvasToRemove.remove()
          $('#canvasSelectDiv')[0].carousel.update()
          @findMiniThumbByCanvasId(cid).remove()
          room.savedOpts.splice room.savedOpts.indexOf(@findOptsById(cid)), 1
          @selectThumb $("#canvasSelectDiv div:first .clink")
      else
        @erase()
        room.savedOpts = []
        @deinitializeFirst()

      room.socket.emit "removeCanvas", canvasId: cid if emit

    onClearClick: ->
      if confirm "Are you sure? This will delete all canvas content."
        @clear true

    #hides elements and emits canvas cleared event
    clear: (emit) ->
      items = []
      for element in opts.historytools.allHistory
        continue if element.isImage
        element.opacity = 0 if not element.actionType
        room.comments.hideComment(element.commentMin) if element.commentMin
        items.push element
      room.history.add actionType: "clear", tools: items, eligible: true if emit

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

    getFitToImage: (dontEnlarge = true)->
      w = paper.project.view.viewSize.width / opts.image.width
      # +20 to let the user see that whole image is fit into canvas
      h = (paper.project.view.viewSize.height - @getViewportAdjustY())/ (opts.image.height + 20)
      r = if h < w then h else w
      return null if r > 1 and dontEnlarge
      return r

    setScale: (scale, skipUpdateAmount = false) ->
      # if first time scale
      scale = 1 if not scale and not opts.currentScale
      return unless scale

      scale = 0.01 if scale <= 0.01
      scale = 4 if scale >= 4

      firstTimeScale = opts.currentScale is null
      $("#scaleAmount").html "#{parseInt(scale * 100)}%" unless skipUpdateAmount

      previousScale = opts.currentScale
      finalScale = scale / room.sharedOpts.scale
      opts.currentScale = scale
      room.sharedOpts.scale = scale

      transformMatrix = new Matrix(finalScale, 0, 0, finalScale, 0, 0)
      paper.project.activeLayer.transform(transformMatrix)

      if previousScale != scale
        finalScale = scale if firstTimeScale
        for element in opts.historytools.allHistory
          if element.commentMin
            element.commentMin.css({top: element.commentMin.position().top * finalScale,
            left: element.commentMin.position().left * finalScale})

            commentMax = element.commentMin[0].$maximized
            commentMax.css({top: commentMax.position().top * finalScale, left: commentMax.position().left * finalScale})

            room.comments.redrawArrow(element.commentMin)

      prevScaledCenter = opts.scaledCenter
      opts.scaledCenter = room.applyCurrentScale paper.view.center
      room.items.pan new Point(opts.scaledCenter.x - prevScaledCenter.x, opts.scaledCenter.y - prevScaledCenter.y)

      room.redraw()

    download: (downloadLink) ->
      cid = $(downloadLink).parents(".canvasPreviewDiv").find(".clink").data("cid")
      @flushCanvasIntoCopy cid

      dataURL = $("#copyCanvas")[0].toDataURL("image/png")
      $.post '/projects/prepareDownload', {pid: $("#pid").val(), canvasData: dataURL}, (data, status, xhr) =>
        window.location = "/projects/download?pid=#{$("#pid").val()}&img=#{data}"

    addScale: (slow = false) ->
      opts.scaleChanged = true
      @setScale(room.sharedOpts.scale + if slow then 0.02 else 0.1)

    subtractScale: (slow = false)->
      opts.scaleChanged = true
      @setScale(room.sharedOpts.scale - if slow then 0.02 else 0.1)

    getViewportAdjustX: -> if App.chat.isVisible() then 300 else 0

    getViewportAdjustY: -> $("#canvasFooter").height()

    getViewportSize: ->
      w: $("#mainCanvas").width() - @getViewportAdjustX()
      h: $("#mainCanvas").height() - @getViewportAdjustY()

    # CANVAS THUMBNAILS & IMAGE UPLOAD

    foldPreviews: ->
      $("#canvasFolder").addClass("canvasFolderTrans")
      $("#canvasFooter").animate {height: 35}, queue: false, complete: ->
        $("#canvasFolder").removeClass("canvasFolderTrans").attr("src", "/images/room/new/hide_icon_up.png")

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
        $("#canvasFolder").removeClass("canvasFolderTrans").attr("src", "/images/room/new/hide_icon.png")

      $("#smallCanvasPreviews").animate(left: -500, 500)
      $("#canvasFolder").attr("onclick", "App.room.canvas.foldPreviews(this); return false;")

    requestLinkScreenshot: ->
      link = window.prompt '', 'Enter a link'
      return unless link
      #TODO add function to helpers
      $("#canvasInitButtons").hide()
      $("#loadingProgressWrap").show()
      http = 'http://'
      link = http + link if link.indexOf http
      #TODO check if link is correct
      posX = paper.view.center.x
      posY = paper.view.center.y
      $.post "/canvases/linkscreenshot", pid: $("#pid").val(), link: link, width: 1366, height: 768, posX: posX, posY: posY, (data, status, xhr) =>
        App.room.canvas.handleUpload
          canvasId: data.canvasId
          fileId: data.element.id
          name: data.canvasName
          posX: data.element.posX
          posY: data.element.posY
        , true
        #TODO change to function call
        $("#canvasInitButtons").show()
        $("#loadingProgressWrap").hide()

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
      room.socket.emit "initializeFirstCanvas", firstThumb.data('cid') if emit

    deinitializeFirst: () ->
      firstThumb = $(@getThumbs()[0])
      room.showSplashScreen()
      #initialiaze new empty opts
      @setScale 1
      room.initOpts firstThumb.data("cid")
      firstThumb.attr("data-initialized", "false").data("initialized", "false")

    addEmpty: (canvasData) ->
      @addNewThumbAndSelect canvasData, true
      room.hideSplashScreen()
      App.chat.setChatUnfoldCallback -> $('#canvasSelectDiv')[0].carousel.goToItem($("#canvasSelectDiv .canvasPreviewDiv:last").index())

      gaTrack "Empty canvas", "Created"
      room.socket.emit "canvasAdded", canvasData

    handleUpload: (canvasData, emit) ->
      if @isFirstInitialized()
        room.hideSplashScreen true
        @addNewThumbAndSelect canvasData
      else
        @initializeFirst false

      room.helper.showLoadingDiv()
      @addImage canvasData.fileId, canvasData.posX, canvasData.posY, (raster, executeLoadImage) =>
        executeLoadImage()
        if @getSelectedCanvasId() is canvasData.canvasId
          @setScale @getFitToImage()
          @centerOnImage()
        @updateThumb parseInt(canvasData.canvasId)
        @onEachCanvasLoaded()

      gaTrack "File", "Created"
      room.socket.emit("fileAdded", canvasData) if emit

    addImage: (fileId, posX, posY, loadWrap) ->
      src = "/files/#{$("#pid").val()}/#{fileId}"
      image = $("<img class='hide' src='#{src}'>")
      $("body").append(image)

      fakeImage = new Image()
      fakeImage.src = "/images/blank.jpg"

      img = new Raster(fakeImage)
      img.isImage = true
      img.cid = opts.canvasId
      img.imageLoaded = false
      room.items.insertFirst(img)
      img.fileId = fileId
      opts.image = img
      room.history.add(img)
      self = @

      onload = ->
        img.size.width = image.width()
        img.size.height = image.height()
        img.position = new Point parseInt(posX), parseInt(posY)
        img.setImage(image[0])
        img.imageLoaded = true
        self.onImageLoaded(img.cid)

      $(image).on "load", -> if loadWrap then loadWrap(img, -> onload()) else onload()

      img

    onImageLoaded: (canvasId) -> room.helper.hideLoadingDiv() if opts.canvasId is canvasId

    centerOnImage: (force = false) ->
      # do not center user if the moved the canvas by himself
      userMovedCanvas = true if opts.canvasPanned
      if opts.image and (not userMovedCanvas or force)
        centerX = opts.scaledCenter.x
        centerY = opts.scaledCenter.y
        imageX = opts.image.position.x
        imageY = opts.image.position.y

        viewportAdjustX = @getViewportAdjustX() / 2
        viewportAdjustY = @getViewportAdjustY() / 2
        adjust = room.applyCurrentScale(new Point(viewportAdjustX, viewportAdjustY))

        centerX += adjust.x
        centerY -= adjust.y

        if centerX isnt imageX or centerY isnt imageY
          room.items.pan new Point(centerX - imageX, centerY - imageY)
      room.redraw()

    cancelPan: -> room.items.pan new Point(-opts.pandx, -opts.pandy)

    addNewThumbAndSelect: (canvasData, setDefaultScale = false) ->
      @erase()
      @setScale 1 if setDefaultScale
      room.initOpts(canvasData.canvasId)

      @changeCanvasBg()

      @addNewThumbHtml canvasData
      $("#canvasSelectDiv .clink").removeClass("canvasSelected")
      $("#canvasSelectDiv .canvasPreviewDiv:last .clink").addClass("canvasSelected")
      $(".smallCanvasPreview").removeClass("previewSelected")
      $(".smallCanvasPreview:last").addClass("previewSelected")
      $("#canvasName").html(canvasData.name)

    addNewThumbHtml: (canvasData) ->
      thumb = $("#canvasSelectDiv .canvasPreviewDiv:first").clone()
      thumb.find(".canvasData").remove() # we don't need data associated with another canvas
      thumb.find(".clink").attr("data-cid", canvasData.canvasId).attr("data-fid", canvasData.fileId)
        .attr("data-name", canvasData.name).attr("data-pos-x", canvasData.posX).attr("data-pos-y", canvasData.posY)
        .attr("data-position", canvasData.position)
      $("#canvasSelectDiv").append(thumb)

      mini = $("<div class='smallCanvasPreview tooltipize' title='#{canvasData.name}'></div>")
      mini.attr("data-cid", canvasData.canvasId).attr("data-fid", canvasData.fileId).attr("data-name", canvasData.name)
      $("#smallCanvasPreviews").append(mini)

    updateThumb: (canvasId) ->
      prevOpts = room.getOpts()

      @activateCopyCanvas()
      room.setOpts @findOptsById(canvasId)
      tempSavedOpts  = room.saveTempOpts(opts)
      opts.historytools.allHistory = []
      for tool in tempSavedOpts.history
        opts.historytools.allHistory.push(tool.clone()) if not tool.commentMin and not tool.actionType
      @restore(false, false)
      @cancelPan()

      if opts.image
        room.sharedOpts.scale = 1
        opts.scaledCenter = paper.view.center
        opts.currentScale = 1
        @setScale @getFitToImage(false), true

      thumb = @findThumbByCanvasId(canvasId).find("canvas")
      thumbContext = thumb[0].getContext('2d')
      canvas = paper.project.view.element

      cvw = $(canvas).width()
      cvh = $(canvas).height()
      tw = $(thumb).width()
      th = $(thumb).height()
      sy = th / cvh

      transformMatrix = new Matrix(sy, 0, 0, sy, 0, 0)
      paper.project.activeLayer.transform(transformMatrix)
      room.redraw()

      shift = -((sy * cvw) - tw) / 2

      thumbContext.clearRect(0, 0, tw, th)
      thumbContext.drawImage(canvas, shift, 0) for i in [0..2]

      new Layer()
      paper.project.layers[paper.project.layers.length - 1].activate()
      paper.project.layers[0].remove()

      @activateNormalCanvas()
      room.restoreFromTemp(tempSavedOpts)
      room.setOpts(prevOpts)

    updateSelectedThumb: -> @updateThumb @getSelectedCanvasId()

    getSelectedCanvasId: -> @getSelected().data("cid")

    isFirstInitialized: -> "#{$(@getThumbs()[0]).data("initialized")}" == "true"

    getSelected: -> $(".canvasSelected")

    getThumbs: -> $("#canvasSelectDiv > .canvasPreviewDiv > .clink")

    findThumbByCanvasId: (canvasId) -> $("#canvasSelectDiv .clink[data-cid='#{canvasId}']")

    setCanvasPosition: (cid, pos) ->
      canvasPreviewDiv = @findThumbByCanvasId(cid).parent()
      oldPos = $(".canvasPreviewDiv").index(canvasPreviewDiv)
      if pos < oldPos
        $("#canvasSelectDiv .canvasPreviewDiv:eq(#{pos})").before(canvasPreviewDiv)
      else
        $("#canvasSelectDiv .canvasPreviewDiv:eq(#{pos})").after(canvasPreviewDiv)

    findMiniThumbByCanvasId: (canvasId) -> $(".smallCanvasPreview[data-cid='#{canvasId}']")

    selectMiniThumb: (mini, emit) ->
      cid = $(mini).data("cid")
      @selectThumb @findThumbByCanvasId(cid), emit

    selectThumb: (anchor, emit) ->
      return if $(anchor).hasClass("canvasSelected")

      cid = $(anchor).data("cid")
      canvasOpts = @findOptsById(cid)

      alert("No canvas opts by given canvasId=" + cid) unless canvasOpts

      @erase()
      room.items.unselect()
      room.setOpts canvasOpts
      @restore(true, false)

      @changeCanvasBg()

      newScale = if opts.image and not opts.scaleChanged and @getFitToImage() then @getFitToImage() else opts.currentScale
      @setScale newScale
      @centerOnImage()

      $("#canvasSelectDiv .clink").removeClass("canvasSelected")
      $(anchor).addClass("canvasSelected")
      $(".smallCanvasPreview").removeClass("previewSelected")
      $(@findMiniThumbByCanvasId(cid)).addClass("previewSelected")

      @changeNameHtml $(anchor).data("name")

      room.socket.emit("switchCanvas", cid) if emit
      room.redraw()

    findOptsById: (canvasId) -> return savedOpt for savedOpt in room.savedOpts when savedOpt.canvasId is canvasId

  App.room.canvas = new RoomCanvas
