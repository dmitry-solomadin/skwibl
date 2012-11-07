$ ->
  class RoomItems

    constructor: ->
      @removeImg = new Image()
      @removeImg.src = "/images/remove.png"

    # ITEMS MANIPULATION

    create: (tool, settings) ->
      settings = {} unless settings
      opts.tool = tool unless settings.justCreate

      tool.strokeJoin = "round"

      opts.tool.strokeColor = if settings.color then settings.color else opts.color
      opts.tool.strokeWidth = if settings.width then settings.width else opts.defaultWidth
      opts.tool.fillColor = settings.fillColor if settings.fillColor
      opts.tool.opacity = if settings.opacity then settings.opacity else opts.opacity
      opts.tool.dashArray = if settings.dashArray then settings.dashArray else undefined

      paper.project.activeLayer.addChild(tool)

    removeSelected: ->
      if @selected()
        # add new 'remove' item into history and link it to removed item.
        room.history.add({type: "remove", tool: @selected(), eligible: true})
        @selected().opacity = 0

        room.socket.emit("elementRemove", @selected().elementId)

        @unselect()
        room.redrawWithThumb()

    translateSelected: (deltaPoint) ->
      if @selected()
        @selected().translate(deltaPoint)
        @selected().selectionRect.translate(deltaPoint) if @selected().selectionRect
        room.redraw()

    unselectIfSelected: (elementId) ->
      if @selected() and @selected().selectionRect and @selected().elementId == elementId
        @unselect()

    unselect: ->
      @selected().selectionRect.remove() if @selected() and @selected().selectionRect
      @setSelected(null)

    pan: (dx, dy) ->
      for element in opts.historytools.allHistory
        if element.commentMin
          room.comments.translate(element.commentMin, dx, dy)
        else if !element.type and element.translate
          element.translate(new Point(dx, dy))

    selected: -> opts.selectedTool
    setSelected: (selectedTool)-> opts.selectedTool = selectedTool

    # ITEMS SELECT

    testSelect: (point) ->
      selectTimeDelta = if opts.selectTime then new Date().getTime() - opts.selectTime else undefined

      opts.selectTime = new Date().getTime()
      alreadySelected = @selected() and @selected().selectionRect
      selected = false

      # Select scalers or remove buttton has highest priority.
      if alreadySelected
        if room.helper.elementInArrayContainsPoint(@selected().selectionRect.scalers, point) ||
        (@selected().selectionRect.removeButton && @selected().selectionRect.removeButton.bounds.contains(point))
          selected = true

      # Already selected item has next highest priority if time between selectes was big.
      selected = true if selectTimeDelta > 750 and alreadySelected and @selected().selectionRect.bounds.contains(point)

      unless selected
        previousSelectedTool = @selected()
        for element in room.history.getSelectableTools()
          continue if element.isImage or element.type

          if element.bounds.contains(point)
            @setSelected(element)
            selected = true

          if selectTimeDelta < 750 and @selected() and previousSelectedTool
            if @selected().id == previousSelectedTool.id then continue else break

      @setSelected(null) unless selected

    drawSelectRect: (point) ->
      if @selected()
        @selected().selectionRect = @createSelectionRectangle()
        $("#removeSelected").removeClass("disabled")

        @selected().scalersSelected = true
        if @selected().selectionRect.topLeftScaler.bounds.contains(point)
          @selected().scaleZone = {zx: -1, zy: -1, point: @selected().bounds.bottomRight}
        else if @selected().selectionRect.bottomRightScaler.bounds.contains(point)
          @selected().scaleZone = {zx: 1, zy: 1, point: @selected().bounds.topLeft}
        else if @selected().selectionRect.topRightScaler.bounds.contains(point)
          @selected().scaleZone = {zx: 1, zy: -1, point: @selected().bounds.bottomLeft}
        else if @selected().selectionRect.bottomLeftScaler.bounds.contains(point)
          @selected().scaleZone = {zx: -1, zy: 1, point: @selected().bounds.topRight}
        else
          @selected().scalersSelected = false

        if @selected().selectionRect.removeButton and @selected().selectionRect.removeButton.bounds.contains(point)
          @removeSelected()

    createSelectionRectangle: ->
      bounds = @selected().bounds
      addBound = parseInt(@selected().strokeWidth / 2)

      selectRect = new Path.Rectangle(bounds.x - addBound, bounds.y - addBound,
      bounds.width + (addBound * 2), bounds.height + (addBound * 2))

      width = 8
      halfWidth = width / 2
      topLeftScaler = new Path.Oval(new Rectangle(bounds.x - addBound - halfWidth,
      bounds.y - addBound - halfWidth, width, width))
      bottomRightScaler = new Path.Oval(new Rectangle(bounds.x + bounds.width + addBound - halfWidth,
      bounds.y + bounds.height + addBound - halfWidth, width, width))
      topRightScaler = new Path.Oval(new Rectangle(bounds.x + bounds.width + addBound - halfWidth,
      bounds.y - addBound - halfWidth, width, width))
      bottomLeftScaler = new Path.Oval(new Rectangle(bounds.x - addBound - halfWidth,
      bounds.y + bounds.height + addBound - halfWidth, width, width))

      unless @selected().commentMin
        removeButton = new Raster(@removeImg)
        removeButton.position = new Point(selectRect.bounds.x + selectRect.bounds.width + 12, selectRect.bounds.y - 12)

      selectionRectGroup = new Group([selectRect, topLeftScaler, bottomRightScaler, topRightScaler, bottomLeftScaler])

      selectionRectGroup.theRect = selectRect
      selectionRectGroup.topLeftScaler = topLeftScaler
      selectionRectGroup.bottomRightScaler = bottomRightScaler
      selectionRectGroup.topRightScaler = topRightScaler
      selectionRectGroup.bottomLeftScaler = bottomLeftScaler
      selectionRectGroup.scalers = [topLeftScaler, bottomRightScaler, topRightScaler, bottomLeftScaler]

      unless @selected().commentMin
        selectionRectGroup.removeButton = removeButton
        selectionRectGroup.addChild(removeButton)

      dashArray = [3, 3]
      @create(selectRect, {color: "#a0a0aa", width: 0.5, opacity: 1, dashArray: dashArray})
      @create(topLeftScaler, {color: "#202020", width: 1, opacity: 1, fillColor: "white"})
      @create(bottomRightScaler, {color: "#202020", width: 1, opacity: 1, fillColor: "white"})
      @create(topRightScaler, {color: "#202020", width: 1, opacity: 1, fillColor: "white"})
      @create(bottomLeftScaler, {color: "#202020", width: 1, opacity: 1, fillColor: "white"})

      @create(removeButton) unless @selected().commentMin

      return selectionRectGroup

    # ITEMS SCALE

    sacleSelected: (event) ->
      scaleZone = @getReflectZone(@selected(), event.point.x, event.point.y)
      if scaleZone then @selected().scaleZone = scaleZone else scaleZone = @selected().scaleZone

      zx = scaleZone.zx
      zy = scaleZone.zy
      scalePoint = scaleZone.point

      scaleFactors = @getScaleFactors(@selected(), zx, zy, event.delta.x, event.delta.y)
      sx = scaleFactors.sx
      sy = scaleFactors.sy

      transformMatrix = new Matrix().scale(sx, sy, scalePoint)
      return if transformMatrix._d == 0 or transformMatrix._a == 0

      if @selected().arrow
        @selected().arrow.scale(sx, sy, scalePoint)
        @selected().drawTriangle()
      else
        @selected().transform(transformMatrix)

      @selected().selectionRect.theRect.transform(transformMatrix)

      # redraw selection rect
      @selected().selectionRect.remove()
      @selected().selectionRect = @createSelectionRectangle()

    getScaleFactors: (item, zx, zy, dx, dy) ->
      item = if item.arrow then item.arrow else item
      w = item.bounds.width
      h = item.bounds.height

      return sx: Math.abs((w - dx) / w), sy: Math.abs((h - dy) / h) if zx == -1 and zy == -1
      return sx: Math.abs((w + dx) / w), sy: Math.abs((h - dy) / h) if zx == 1 and zy == -1
      return sx: Math.abs((w - dx) / w), sy: Math.abs((h + dy) / h) if zx == -1 and zy == 1
      return sx: Math.abs((w + dx) / w), sy: Math.abs((h + dy) / h) if zx == 1 and zy == 1

    getReflectZone: (item, x, y) ->
      itemToScale = if item.arrow then item.arrow else item

      return null if itemToScale.bounds.contains(x, y)
      # preserve zone

      w = itemToScale.bounds.width
      h = itemToScale.bounds.height
      center = new Point(itemToScale.bounds.topLeft.x + (w / 2), itemToScale.bounds.topLeft.y + (h / 2))
      cx = center.x
      cy = center.y

      if x <= cx and y <= cy
        zone = {zx: -1, zy: -1, point: itemToScale.bounds.bottomRight}
      else if x >= cx and y <= cy
        zone = {zx: 1, zy: -1, point: itemToScale.bounds.bottomLeft}
      else if x <= cx and y >= cy
        zone = {zx: -1, zy: 1, point: itemToScale.bounds.topRight}
      else if x >= cx and y >= cy
        zone = {zx: 1, zy: 1, point: itemToScale.bounds.topLeft}

      dzx = zone.zx + item.scaleZone.zx
      dzy = zone.zy + item.scaleZone.zy

      if dzx == 0 and dzy == 0 and w < 3 and h < 3
        itemToScale.scale(-1, -1)
        return zone
      else if dzx == 0 and dzy != 0 and w < 3
        itemToScale.scale(-1, 1)
        return zone
      else if dzy == 0 and dzx != 0 and h < 3
        itemToScale.scale(1, -1)
        return zone
      else
        return null

  App.room.items = new RoomItems