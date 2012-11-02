$ ->
  class RoomItems extends App.RoomComponent

    constructor: ->
      @removeImg = new Image()
      @removeImg.src = "/images/remove.png"

    # ITEMS MANIPULATION

    create: (tool, settings) ->
      settings = {} unless settings
      @opts().tool = tool unless settings.justCreate

      @opts().tool.strokeColor = if settings.color then settings.color else @opts().color
      @opts().tool.strokeWidth = if settings.width then settings.width else @opts().defaultWidth
      @opts().tool.fillColor = settings.fillColor if settings.fillColor
      @opts().tool.opacity = if settings.opacity then settings.opacity else @opts().opacity
      @opts().tool.dashArray = if settings.dashArray then settings.dashArray else undefined

    removeSelected: ->
      if @opts().selectedTool
        # add new 'remove' item into history and link it to removed item.
        @room().history.add({type: "remove", tool: @opts().selectedTool, eligible: true})
        @opts().selectedTool.opacity = 0

        @room().socket.emit("elementRemove", @opts().selectedTool.elementId)

        @unselect()
        @room().redrawWithThumb()

    translateSelected: (deltaPoint) ->
      if @opts().selectedTool
        @opts().selectedTool.translate(deltaPoint)
        @opts().selectedTool.selectionRect.translate(deltaPoint) if @opts().selectedTool.selectionRect
        @room().redrawWithThumb()

    unselectIfSelected: (elementId) ->
      if @opts().selectedTool and @opts().selectedTool.selectionRect and @opts().selectedTool.elementId == elementId
        @unselect()

    unselect: () ->
      @opts().selectedTool.selectionRect.remove() if @opts().selectedTool and @opts().selectedTool.selectionRect
      @opts().selectedTool = null;

    # ITEMS SELECT

    testSelect: (point) ->
      selectTimeDelta = if @opts().selectTime then new Date().getTime() - @opts().selectTime else undefined

      @opts().selectTime = new Date().getTime()
      alreadySelected = @opts().selectedTool and @opts().selectedTool.selectionRect
      selected = false

      # Select scalers or remove buttton has highest priority.
      if alreadySelected
        if @room().helper.elementInArrayContainsPoint(@opts().selectedTool.selectionRect.scalers, point) ||
        (@opts().selectedTool.selectionRect.removeButton && @opts().selectedTool.selectionRect.removeButton.bounds.contains(point))
          selected = true

      # Already selected item has next highest priority if time between selectes was big.
      selected = true if selectTimeDelta > 750 and alreadySelected and @opts().selectedTool.selectionRect.bounds.contains(point)

      unless selected
        previousSelectedTool = @opts().selectedTool
        for element in @room().history.getSelectableTools()
          continue if element.isImage or element.type

          if element.bounds.contains(point)
            @opts().selectedTool = element
            selected = true

          if selectTimeDelta < 750 and @opts().selectedTool and previousSelectedTool
              if @opts().selectedTool.id == previousSelectedTool.id then continue else break

      @opts().selectedTool = null unless selected

    drawSelectRect: (point) ->
      tool = @opts().selectedTool
      if tool
        tool.selectionRect = @createSelectionRectangle(tool)
        $("#removeSelected").removeClass("disabled")

        tool.scalersSelected = true
        if tool.selectionRect.topLeftScaler.bounds.contains(point)
          tool.scaleZone = {zx: -1, zy: -1, point: tool.bounds.bottomRight}
        else if tool.selectionRect.bottomRightScaler.bounds.contains(point)
          tool.scaleZone = {zx: 1, zy: 1, point: tool.bounds.topLeft}
        else if tool.selectionRect.topRightScaler.bounds.contains(point)
          tool.scaleZone = {zx: 1, zy: -1, point: tool.bounds.bottomLeft}
        else if tool.selectionRect.bottomLeftScaler.bounds.contains(point)
          tool.scaleZone = {zx: -1, zy: 1, point: tool.bounds.topRight}
        else
          tool.scalersSelected = false

        if tool.selectionRect.removeButton and tool.selectionRect.removeButton.bounds.contains(point)
          @removeSelected()

    createSelectionRectangle: (selectedTool) ->
      bounds = selectedTool.bounds
      addBound = parseInt(selectedTool.strokeWidth / 2)

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

      unless selectedTool.commentMin
        removeButton = new Raster(@removeImg)
        removeButton.position = new Point(selectRect.bounds.x + selectRect.bounds.width + 12, selectRect.bounds.y - 12)

      selectionRectGroup = new Group([selectRect, topLeftScaler, bottomRightScaler, topRightScaler, bottomLeftScaler])

      selectionRectGroup.theRect = selectRect
      selectionRectGroup.topLeftScaler = topLeftScaler
      selectionRectGroup.bottomRightScaler = bottomRightScaler
      selectionRectGroup.topRightScaler = topRightScaler
      selectionRectGroup.bottomLeftScaler = bottomLeftScaler
      selectionRectGroup.scalers = [topLeftScaler, bottomRightScaler, topRightScaler, bottomLeftScaler]

      unless selectedTool.commentMin
        selectionRectGroup.removeButton = removeButton
        selectionRectGroup.addChild(removeButton)

      dashArray = [3, 3]
      @create(selectRect, {color: "#a0a0aa", width: 0.5, opacity: 1, dashArray: dashArray})
      @create(topLeftScaler, {color: "#202020", width: 1, opacity: 1, fillColor: "white"})
      @create(bottomRightScaler, {color: "#202020", width: 1, opacity: 1, fillColor: "white"})
      @create(topRightScaler, {color: "#202020", width: 1, opacity: 1, fillColor: "white"})
      @create(bottomLeftScaler, {color: "#202020", width: 1, opacity: 1, fillColor: "white"})

      @create(removeButton) unless selectedTool.commentMin

      return selectionRectGroup

    # ITEMS SCALE

    doScale: (tool, sx, sy, scalePoint) ->
      transformMatrix = new Matrix().scale(sx, sy, scalePoint)
      return if transformMatrix._d == 0 or transformMatrix._a == 0

      if tool.tooltype == "arrow"
        tool.arrow.scale(sx, sy, scalePoint)
        tool.drawTriangle()
      else
        tool.transform(transformMatrix)

      tool.selectionRect.theRect.transform(transformMatrix)

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