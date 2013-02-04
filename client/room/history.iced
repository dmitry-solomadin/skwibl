$ ->
  class RoomHistory

    prev: ->
      return if room.opts.historyCounter is 0

      executePrevHistory = (item, reverse) =>
        return if item.isImage

        if item.actionType is "remove"
          executePrevHistory(item.tool, true)
        else if item.actionType is "clear"
          executePrevHistory(tool, true) for tool in item.tools
        else if item.commentMin
          if reverse
            room.comments.showComment item.commentMin
            room.socket.emit "commentUpdate", room.socketHelper.prepareCommentToSend(item.commentMin, "create")
          else
            room.comments.hideComment item.commentMin
            room.socket.emit "commentRemove", canvasId: room.canvas.getSelectedCanvasId(), elementId: item.commentMin.elementId
        else
          if reverse
            item.opacity = 1
            room.socket.emit "elementUpdate", room.socketHelper.prepareElementToSend(item, "create")
          else
            room.items.remove false, item

      $("#redoLink").removeClass("disabled")

      opts.historyCounter = opts.historyCounter - 1
      item = opts.historytools.eligibleHistory[opts.historyCounter]
      if item?
        executePrevHistory(item)
        room.redrawWithThumb()

      if opts.historyCounter is 0
        $("#undoLink").addClass("disabled")

    next: ->
      return if opts.historyCounter is opts.historytools.eligibleHistory.length

      executeNextHistory = (item, reverse) =>
        return if item.isImage

        if item.actionType is "remove"
          executeNextHistory(item.tool, true)
        else if item.actionType is "clear"
          executeNextHistory(tool, true) for tool in item.tools
        else if item.commentMin
          if reverse
            room.comments.hideComment item.commentMin
            room.socket.emit "commentRemove", canvasId: room.canvas.getSelectedCanvasId(), elementId: item.commentMin.elementId
          else
            room.comments.showComment item.commentMin
            room.socket.emit "commentUpdate", room.socketHelper.prepareCommentToSend(item.commentMin, "create")
        else
          if reverse
            room.items.remove false, item
          else
            item.opacity = 1
            room.socket.emit "elementUpdate", room.socketHelper.prepareElementToSend(item, "create")

      $("#undoLink").removeClass("disabled")

      item = opts.historytools.eligibleHistory[opts.historyCounter]
      if item?
        executeNextHistory(item)
        opts.historyCounter = opts.historyCounter + 1
        room.redrawWithThumb()

      if opts.historyCounter is opts.historytools.eligibleHistory.length
        $("#redoLink").addClass("disabled")

    # get all tools that are visible and have special marker
    getSelectableTools: ->
      selectableTools = []
      for tool in opts.historytools.allHistory
        selectableTools.push(tool) if tool.opacity

      selectableTools

    add: (tool) ->
      tool = tool or room.items.created
      if opts.historyCounter isnt opts.historytools.eligibleHistory.length # rewrite history
        opts.historytools.eligibleHistory = opts.historytools.eligibleHistory.slice(0, room.opts.historyCounter)

      opts.historytools.eligibleHistory.push(tool) if tool.eligible
      opts.historytools.allHistory.push(tool)

      opts.historyCounter = opts.historytools.eligibleHistory.length

      if tool.eligible
        $("#undoLink").removeClass("disabled")
        $("#redoLink").addClass("disabled")

  App.room.history = new RoomHistory
