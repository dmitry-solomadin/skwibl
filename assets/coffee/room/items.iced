$ ->
  class RoomItems

    constructor: ->
      @removeImg = new Image()
      @removeImg.src = "/images/room/remove.png"

    # ITEMS MANIPULATION

    create: (tool, settings) ->
      #TODO change behavior to remove this method it creates nothing
      console.log 'create'
      settings = settings or {}
      opts.tool = tool unless settings.justCreate

      tool.strokeJoin = "round"

      opts.tool.strokeColor = settings.color or sharedOpts.color
      opts.tool.strokeWidth = settings.width or opts.defaultWidth
      opts.tool.fillColor = settings.fillColor
      opts.tool.opacity = settings.opacity or opts.opacity
      opts.tool.dashArray = settings.dashArray

    remove: (historize = true, item = @sel) ->
      console.log 'remove'
      return unless item
      room.history.add(
        actionType: "remove"
        tool: item
        eligible: true) if historize
      item.opacity = 0
      room.socket.emit("elementRemove", item.elementId)
      @unselect item.elementId
      room.redrawWithThumb()

    translate: (delta, item = @sel) ->
      console.log 'translate selected'
      return unless item
      item.translate(delta)
      item.selectionRect?.translate(delta)

    unselect: (id = @sel?.elementId) ->
      rect = @sel?.selectionRect
      if rect and @sel.elementId is id
        rect.remove()
        @setSelected(null)

    pan: (dx, dy) ->
      #TODO move history logic out of this method
      console.log 'pan'
      opts.pandx += dx
      opts.pandy += dy
      for el in opts.historytools.allHistory
        if el.commentMin
          room.comments.translate(el.commentMin, dx, dy)
        else if not el.actionType and el.translate
          el.translate(new Point(dx, dy))

    #TODO consider how to make this setter an action - select
    setSelected: (item)-> @sel = item

    # ITEMS SELECT

    testSelect: (point) ->
      console.log 'test sel'
      selectTimeDelta = Date.now() - opts.selectTime if opts.selectTime
      opts.selectTime = Date.now()
      rect = @sel?.selectionRect
      isSelected = rect?
      selected = false
      # Select scalers or remove button has highest priority.
      if isSelected
        if rect.removeButton?.bounds.contains(point) or room.helper.containsPoint(rect.scalers, point)
          selected = true
      # Already selected item has next highest priority if time between selectes was big.
      selected = selectTimeDelta > 750 and isSelected and rect.bounds.contains(point)
      unless selected
        prevSel = @sel
        for el in room.history.getSelectableTools()
          continue if el.isImage or el.actionType
          if el.bounds.contains(point)
            @setSelected(el)
            selected = true
          if selectTimeDelta < 750 and @sel and prevSel
            if @sel.id is prevSel.id then continue else break
      @setSelected(null) unless selected

    drawSelRect: (point) ->
      console.log 'draw sel'
      if @sel
        @sel.selectionRect = @createSelRect()
        $("#removeSelected").removeClass("disabled")
        rect = @sel.selectionRect
        bounds = @sel.bounds
        @sel.scalersSelected = true
        if rect.scalers.nw.bounds.contains(point)
          @sel.scaleZone =
            zx: -1
            zy: -1
            point: bounds.bottomRight
        else if rect.scalers.se.bounds.contains(point)
          @sel.scaleZone =
            zx: 1
            zy: 1
            point: bounds.topLeft
        else if rect.scalers.ne.bounds.contains(point)
          @sel.scaleZone =
            zx: 1
            zy: -1
            point: bounds.bottomLeft
        else if rect.scalers.sw.bounds.contains(point)
          @sel.scaleZone =
            zx: -1
            zy: 1
            point: bounds.topRight
        else
          @sel.scalersSelected = false
        if rect.removeButton?.bounds.contains(point)
          @remove()

    createSelRect: ->
      console.log 'create sel'
      bounds = @sel.bounds
      addBound = parseInt(@sel.strokeWidth / 2)
      selRect = new Path.Rectangle(bounds.x - addBound, bounds.y - addBound,
      bounds.width + (addBound * 2), bounds.height + (addBound * 2))
      #TODO move constants to options
      width = 4
      outstend = 12
      selDash = [3, 3]
      nw = new Path.Circle(new Point(bounds.x - addBound, bounds.y - addBound), width)
      se = new Path.Circle(new Point(bounds.x + bounds.width + addBound, bounds.y + bounds.height + addBound), width)
      ne = new Path.Circle(new Point(bounds.x + bounds.width + addBound, bounds.y - addBound), width)
      sw = new Path.Circle(new Point(bounds.x - addBound, bounds.y + bounds.height + addBound), width)
      unless @sel.commentMin
        removeButton = new Raster(@removeImg)
        removeButton.position = new Point(selRect.bounds.x + selRect.bounds.width + outstend, selRect.bounds.y - outstend)
      selGroup = new Group([selRect, nw, se, ne, sw])
      selGroup.theRect = selRect
      selGroup.scalers =
        nw: nw
        se: se
        ne: ne
        sw: sw
      unless @sel.commentMin
        selGroup.removeButton = removeButton
        selGroup.addChild(removeButton)
      @create(selRect, {color: "#a0a0aa", width: 0.5, opacity: 1, dashArray: selDash})
      for key, scaler of selGroup.scalers
        @create(scaler, {color: "#202020", width: 1, opacity: 1, fillColor: "white"})
      @create(removeButton) unless @sel.commentMin
      return selGroup

    # ITEMS SCALE

    sacleSelected: (event) ->
      console.log 'scale selected'
      scaleZone = @getReflectZone(@sel, event.point.x, event.point.y)
      if scaleZone then @sel.scaleZone = scaleZone else scaleZone = @sel.scaleZone

      zx = scaleZone.zx
      zy = scaleZone.zy
      scalePoint = scaleZone.point

      scaleFactors = @getScaleFactors(@sel, zx, zy, event.delta.x, event.delta.y)
      sx = scaleFactors.sx
      sy = scaleFactors.sy

      transformMatrix = new Matrix().scale(sx, sy, scalePoint)
      return unless sx and sy

      if @sel.arrow
        @sel.arrow.scale(sx, sy, scalePoint)
        @sel.drawTriangle()
      else
        @sel.transform(transformMatrix)

      # redraw selection rect
      @sel.selectionRect.remove()
      @sel.selectionRect = @createSelRect()

    getScaleFactors: (item, zx, zy, dx, dy) ->
      console.log 'get scale factors'
      item = item.arrow or item
      w = item.bounds.width
      h = item.bounds.height

      return sx: Math.abs(1 + zx*dx/w), sy: Math.abs(1 + zy*dy/h)

    getReflectZone: (item, x, y) ->
      console.log 'get reflect zone'
      itemToScale = item.arrow or item

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

      if dzx is 0 and dzy is 0 and w < 3 and h < 3
        itemToScale.scale(-1, -1)
        return zone
      else if dzx is 0 and dzy isnt 0 and w < 3
        itemToScale.scale(-1, 1)
        return zone
      else if dzy is 0 and dzx isnt 0 and h < 3
        itemToScale.scale(1, -1)
        return zone
      else
        return null

    # ITEMS MISC
    createUserBadge: (uid, x, y) ->
      console.log 'create user badge'
      getUserIndex = (uid) ->
        for user, index in App.chat.users
          return (index + 1) if "#{user.id}" is "#{uid}"
        return 1
      badge = $("<span class='userBadge label-#{getUserIndex(uid)}'>#{App.chat.getUserById(uid).displayName}</span>")
      left = x + opts.pandx
      top = y + opts.pandy + parseInt($("#header").height())
      badgePos = room.applyReverseCurrentScale(new Point(left, top))
      badge.css
        left: badgePos.x
        top: badgePos.y
      $("body").append(badge)
      fadeOutBadge = -> $(badge).fadeOut('fast')
      setTimeout fadeOutBadge, 2000

    isEmpty: (item) ->
      console.log 'is item empty'
      #TODO this is strange code
      return true unless item
      return false unless item.segments
      return true if item.segments.length is 1
      if item.segments.length is 2
        segmentsAreEqual = item.segments[0].point.x is item.segments[1].point.x and item.segments[0].point.y is item.segments[1].point.y
        return segmentsAreEqual
      return false

    insertFirst: (item) ->
      console.log 'insert first'
      paper.project.activeLayer.insertChild(0, item)

    drawArrow: (arrowLine) ->
      console.log 'draw arrow'
      arrowGroup = new Group([arrowLine])
      arrowGroup.arrow = arrowLine
      arrowGroup.drawTriangle = => @drawArrowTriangle arrowGroup
      triangle = arrowGroup.drawTriangle()
      @create(triangle)
      arrowGroup

    drawArrowTriangle: (group) ->
      console.log 'draw arrow triangle'
      arrow = group.arrow
      arrowLastX = arrow.lastSegment.point.x
      arrowLastY = arrow.lastSegment.point.y
      arrowFirstX = arrow.segments[0].point.x
      arrowFirstY = arrow.segments[0].point.y
      triangle = group.triangle
      vector = new Point(arrowLastX - arrowFirstX, arrowLastY - arrowFirstY)
      vector = vector.normalize(10)
      vPlus = vector.rotate(135)
      vMinus = vector.rotate(-135)
      if triangle
        triangle.segments[0].point = new Point(arrowLastX + vPlus.x, arrowLastY + vPlus.y)
        triangle.segments[1].point = arrow.lastSegment.point
        triangle.segments[2].point = new Point(arrowLastX + vMinus.x, arrowLastY + vMinus.y)
      else
        triangle = new Path([
          new Point(arrowLastX + vPlus.x, arrowLastY + vPlus.y)
          arrow.lastSegment.point
          new Point(arrowLastX + vMinus.x, arrowLastY + vMinus.y)
        ])
        group.triangle = triangle
        group.addChild(triangle)
      group.triangle

  App.room.items = new RoomItems
