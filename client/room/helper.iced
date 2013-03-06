$ ->
  class RoomHelper

    initHotkeys: ->
      if isMac()
        $(document).bind 'keydown.meta_z', => room.history.prev()
        $(document).bind 'keydown.meta_shift_z', => room.history.next()
      else
        $(document).bind 'keydown.ctrl_z', => room.history.prev()
        $(document).bind 'keydown.ctrl_shift_z', => room.history.next()

      $(document).bind 'keydown.del', => room.items.remove()
      $(document).bind 'keydown.backspace', => room.items.remove()
      $(document).bind 'keydown.left', =>
        room.items.translate(new Point(-5, 0))
        room.redrawWithThumb()
      $(document).bind 'keydown.up', =>
        room.items.translate(new Point(0, -5))
        room.redrawWithThumb()
      $(document).bind 'keydown.right', =>
        room.items.translate(new Point(5, 0))
        room.redrawWithThumb()
      $(document).bind 'keydown.down', =>
        room.items.translate(new Point(0, 5))
        room.redrawWithThumb()
      $(document).bind 'keydown.shift_left', =>
        room.items.translate(new Point(-1, 0))
        room.redrawWithThumb()
      $(document).bind 'keydown.shift_up', =>
        room.items.translate(new Point(0, -1))
        room.redrawWithThumb()
      $(document).bind 'keydown.shift_right', =>
        room.items.translate(new Point(1, 0))
        room.redrawWithThumb()
      $(document).bind 'keydown.shift_down', =>
        room.items.translate(new Point(0, 1))
        room.redrawWithThumb()

    initMousewheel: ->
      $('#mainCanvas').on 'mousewheel', (event, delta, deltaX, deltaY) ->
        if delta > 0 then room.canvas.addScale(true) else room.canvas.subtractScale(true)

    initUploader: ->
      percents = {}
      firstFile = true
      id = 1
      results = []

      showButtons = ->
        $("#canvasInitButtons").show()
        $("#loadingProgressWrap").hide()

      $('#fileupload').fileupload
        dataType: 'json'
        url: '/file/upload'
        done: (e, data) =>
          results.push data.result[0]
          if results.length is data.originalFiles.length
            showButtons()
            # on local machine files sometimes uploaded before fadeOut is finished so we ensure that buttons will be displayed
            setTimeout showButtons, 500

            for file in results
              room.canvas.handleUpload
                canvasId: parseInt(file.canvasId)
                fileId: file.element.id
                name: file.canvasName
                posX: file.element.posX
                posY: file.element.posY
              , true

            firstFile = true
            id = 1
            results = []
            percents = {}

      $('#fileupload').bind 'fileuploadstart', (e, data) ->
        $("#canvasInitButtons").fadeOut()
        $("#loadingProgressWrap .bar").css("width", "0%")
        $("#loadingProgressWrap").fadeIn()

      $('#fileupload').bind 'fileuploadprogress', (e, data) ->
        percents["#{data.files[0].id}"] = data.loaded * (data.files[0].percentInTotal) / data.total

        percentTotal = 0
        for percentId of percents
          percentPart = percents[percentId]
          percentTotal += percentPart

        $("#loadingProgressWrap .bar").css("width", "#{percentTotal}%")

      $('#fileupload').bind 'fileuploadsubmit', (e, data) ->
        overallSize = 0
        overallSize += file.size for file in data.originalFiles
        data.files[0].percentInTotal = (data.files[0].size * 100 / overallSize).toFixed(2)
        data.files[0].id = id
        id++
        params =
          pid: $("#pid").val()
          posX: paper.view.center.x
          posY: paper.view.center.y
        # we only add cid for the first canvas.
        params.cid = App.room.canvas.getSelectedCanvasId() if not room.canvas.isFirstInitialized() and firstFile
        firstFile = false
        data.formData = params

    showLoadingDiv: ->
      left = ($(window).width() + room.canvas.getViewportAdjustX()) / 2
      top = ($(window).height() - room.canvas.getViewportAdjustY()) / 2
      $("#loading-div").css
        top: top
        left: left
        display: "block"

    hideLoadingDiv: -> $("#loading-div").hide()

    reverseOpacity: (elem) -> elem.opacity = 1 - elem.opacity

    notifyComment: -> App.notificator.notify("Select an area to comment.")

    containsPoint: (array, point) ->
      for element in array
        return element if element.bounds.contains point
      return null

    findAndRemoveByElementId: (id) ->
      return null unless id

      for element, index in opts.historytools.allHistory
        if element.elementId is id or (element.commentMin and element.commentMin.elementId is id)
          opts.historytools.allHistory.splice(index, 1)
          return element

      return null

    findByElementId: (id) ->
      return null unless id

      for element in opts.historytools.allHistory
        return element if element.commentMin and "#{element.commentMin.elementId}" is "#{id}"
        return element if "#{element.elementId}" is "#{id}"
      return null

    findByElementIdAllCanvases: (id) ->
      return null unless id

      for savedOpt in room.savedOpts
        for element in savedOpt.historytools.allHistory
          if element.commentMin
            if element.commentMin and "#{element.commentMin.elementId}" is "#{id}"
              return canvasId: savedOpt.canvasId, element: element
          if "#{element.elementId}" is "#{id}"
            return canvasId: savedOpt.canvasId, element: element

      return null

    findById: (id) ->
      # we don't have more than two levels of children (and won't have probably) so no need for recursion
      for element in paper.project.activeLayer.children
        return element if element.id is id
        if element.children and element.children.length
          return child for child in element.children when child.id is id

  App.room.helper = new RoomHelper
