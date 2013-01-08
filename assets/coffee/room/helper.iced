$ ->
  class RoomHelper

    initHotkeys: ->
      if isMac()
        $(document).bind 'keydown.meta_z', => room.history.prev()
        $(document).bind 'keydown.meta_shift_z', => room.history.next()
      else
        $(document).bind 'keydown.ctrl_z', => room.history.prev()
        $(document).bind 'keydown.ctrl_shift_z', => room.history.next()

      $(document).bind 'keydown.del', => room.items.removeSelected()
      $(document).bind 'keydown.backspace', => room.items.removeSelected()
      $(document).bind 'keydown.left', => room.items.translateSelected(new Point(-5, 0))
      $(document).bind 'keydown.up', => room.items.translateSelected(new Point(0, -5))
      $(document).bind 'keydown.right', => room.items.translateSelected(new Point(5, 0))
      $(document).bind 'keydown.down', => room.items.translateSelected(new Point(0, 5))
      $(document).bind 'keydown.shift_left', => room.items.translateSelected(new Point(-1, 0))
      $(document).bind 'keydown.shift_up', => room.items.translateSelected(new Point(0, -1))
      $(document).bind 'keydown.shift_right', => room.items.translateSelected(new Point(1, 0))
      $(document).bind 'keydown.shift_down', => room.items.translateSelected(new Point(0, 1))

    initUploader: ->
      $('#fileupload').fileupload
        dataType: 'json'
        url: '/file/upload'
        done: (e, data) ->
          for file in data.result
            room.canvas.handleUpload {canvasId: file.canvasId, fileId: file.element.id, name: file.canvasName}, true

      firstFile = true
      $('#fileupload').bind 'fileuploadsubmit', (e, data) ->
        params =
          pid: $("#pid").val()
        # we only add cid for the first canvas.
        params.cid = App.room.canvas.getSelectedCanvasId() if not room.canvas.isSelectedInitialized() and firstFile
        firstFile = false
        data.formData = params

    reverseOpacity: (elem) -> elem.opacity = 1 - elem.opacity

    notifyComment: -> App.notificator.notify("Drag to comment an area.")

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
            console.log element.commentMin.elementId
            if element.commentMin and "#{element.commentMin.elementId}" is "#{id}"
              return canvasId: savedOpt.canvasId, element: element
          if "#{element.elementId}" is "#{id}"
            return canvasId: savedOpt.canvasId, element: element

      return null

    findById: (id) ->
      for element in paper.project.activeLayer.children
        return element if element.id is id

  App.room.helper = new RoomHelper
