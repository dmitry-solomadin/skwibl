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
      uploader = new qq.FileUploader
        element: $('#file-uploader')[0]
        action: '/file/upload'
        title_uploader: 'Upload'
        failed: 'Failed'
        multiple: true
        cancel: 'Cancel'
        debug: false
        params:
          pid: $("#pid").val()
        onSubmit: (id, fileName) =>
          $(uploader._listElement).css('dispaly', 'none')
        onComplete: (id, fileName, responseJSON) =>
          $(uploader._listElement).css('dispaly', 'none')

          imagePath = "/images/avatar.png"
          room.canvas.handleUpload(imagePath, true)

    reverseOpacity: (elem) -> if elem.opacity == 0 then elem.opacity = 1 else elem.opacity = 0

    notifyComment: -> App.notificator.notify("Drag to comment an area.")

    elementInArrayContainsPoint: (array, point) ->
      for element in array
        return element if element.bounds.contains point
      return null

    findByElementId: (id) ->
      return null unless id

      for element in opts.historytools.allHistory
        return element if element.commentMin and element.commentMin.elementId == id
        return element if element.elementId == id
      return null

  App.room.helper = new RoomHelper