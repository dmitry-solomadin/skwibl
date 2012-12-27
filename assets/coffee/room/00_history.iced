$ ->
  class RoomHistory

    prev: ->
      return if room.opts.historyCounter == 0

      executePrevHistory = (item, reverse) =>
        if item.actionType == "remove"
          executePrevHistory(item.tool, true)
        else if item.actionType == "clear"
          $(item.tools).each -> executePrevHistory(@, true)
        else if item.commentMin
          if reverse
            room.comments.showComment item.commentMin
            room.socket.emit "commentUpdate", room.socketHelper.prepareCommentToSend item.commentMin
          else
            room.comments.hideComment item.commentMin
            room.socket.emit "commentRemove", item.commentMin.elementId
        else
          if reverse
            item.opacity = 1
            room.socket.emit "elementUpdate", room.socketHelper.prepareElementToSend item
          else
            room.items.remove item, false

      $("#redoLink").removeClass("disabled")

      opts.historyCounter = opts.historyCounter - 1
      item = opts.historytools.eligibleHistory[opts.historyCounter]
      if item?
        executePrevHistory(item)
        room.redrawWithThumb()

      if opts.historyCounter == 0
        $("#undoLink").addClass("disabled")

    next: ->
      return if opts.historyCounter == opts.historytools.eligibleHistory.length

      executeNextHistory = (item, reverse) =>
        if item.actionType == "remove"
          executeNextHistory(item.tool, true)
        else if item.actionType == "clear"
          $(item.tools).each -> executeNextHistory(@, true)
        else if item.commentMin
          if reverse
            room.comments.hideComment item.commentMin
            room.socket.emit "commentRemove", item.commentMin.elementId
          else
            room.comments.showComment item.commentMin
            room.socket.emit "commentUpdate", room.socketHelper.prepareCommentToSend item.commentMin
        else
          if reverse
            room.items.remove item, false
          else
            item.opacity = 1
            room.socket.emit "elementUpdate", room.socketHelper.prepareElementToSend item

      $("#undoLink").removeClass("disabled")

      item = opts.historytools.eligibleHistory[opts.historyCounter]
      if item?
        executeNextHistory(item)
        opts.historyCounter = opts.historyCounter + 1
        room.redrawWithThumb()

      if opts.historyCounter == opts.historytools.eligibleHistory.length
        $("#redoLink").addClass("disabled")

    # get all tools that are visible and have special marker
    getSelectableTools: ->
      selectableTools = []
      for tool in opts.historytools.allHistory
        selectableTools.push(tool) if tool.opacity != 0

      selectableTools

    add: (tool) ->
      tool = if tool then tool else opts.tool
      if opts.historyCounter != opts.historytools.eligibleHistory.length # rewrite history
        opts.historytools.eligibleHistory = opts.historytools.eligibleHistory.slice(0, room.opts.historyCounter)

      opts.historytools.eligibleHistory.push(tool) if tool.eligible
      opts.historytools.allHistory.push(tool)

      opts.historyCounter = opts.historytools.eligibleHistory.length

      if tool.eligible
        $("#undoLink").removeClass("disabled")
        $("#redoLink").addClass("disabled")

  App.room.history = new RoomHistory