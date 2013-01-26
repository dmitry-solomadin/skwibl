$ ->
  class RoomItems

    constructor: ->
      @removeImg = new Image()
      @removeImg.src = "/images/room/remove.png"

    # ITEMS MANIPULATION

    init: (item, settings) ->
      settings = settings or {}
      item.strokeJoin = "round"
      item.strokeColor = settings.color or sharedOpts.color
      item.strokeWidth = settings.width or opts.defaultWidth
      item.fillColor = settings.fillColor
      item.opacity = settings.opacity or opts.opacity
      item.dashArray = settings.dashArray
      #buffer item for creation process
      @created = item unless settings.noBuffer

    remove: (historize = true, item = @sel) ->
      return unless item
      room.history.add(
        actionType: "remove"
        tool: item #TODO change tool to item
        eligible: true) if historize
      item.opacity = 0
      console.log item
      room.socket.emit("elementRemove", canvasId: room.canvas.getSelectedCanvasId(), elementId: item.elementId)
      @unselect item.elementId
      room.redrawWithThumb()

    translate: (delta, item = @sel) ->
      return unless item
      item.translate(delta)
      item.arrowGroup?.triangle.translate delta
      item.selectionRect?.translate(delta)

    unselect: (id = @sel?.elementId) ->
      rect = @sel?.selectionRect
      if rect and @sel.elementId is id
        rect.remove()
        @setSelected(null)

    pan: (delta) ->
      opts.pandx += delta.x
      opts.pandy += delta.y
      for el in opts.historytools.allHistory
        if el.commentMin
          room.comments.translate el.commentMin, delta
        else if not el.actionType and el.translate
          el.translate delta

    #TODO consider how to make this setter an action - select
    setSelected: (item) -> @sel = item

    # ITEMS SELECT

    testSelect: (point) ->
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
      if @sel
        @sel.selectionRect = @createSelRect()
        $("#removeSelected").removeClass("disabled")
        rect = @sel.selectionRect

        @sel.selectedScaler = null
        for sn, scaler of rect.scalers
          if scaler.bounds.contains point
            @sel.selectedScaler = scaler
            p = @sel.bounds[scaler.name]
            @sel.center = new Point(2*@sel.position.x - p.x, 2*@sel.position.y - p.y)
            @sel.oldPoint = point
            @sel.pzx = if point.x - @sel.center.x > 0 then 1 else -1
            @sel.pzy = if point.y - @sel.center.y > 0 then 1 else -1
            break

        if rect.removeButton?.bounds.contains(point)
          @remove()

    createSelRect: ->
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
      nw.name = "topLeft"
      se.name = "bottomRight"
      ne.name = "topRight"
      sw.name = "bottomLeft"

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
      @init(selRect, {color: "#a0a0aa", width: 0.5, opacity: 1, dashArray: selDash})
      for key, scaler of selGroup.scalers
        @init(scaler, {color: "#202020", width: 1, opacity: 1, fillColor: "white"})
      @init(removeButton) unless @sel.commentMin
      return selGroup

    # ITEMS SCALE
    scale: (event) ->
      return unless @sel

      zx = if event.point.x - @sel.center.x > 0 then 1 else -1
      zy = if event.point.y - @sel.center.y > 0 then 1 else -1

      # zone change
      if @sel.pzx != zx or @sel.pzy != zy
        dzx = @sel.pzx * zx
        dzy = @sel.pzy * zy
        ssx = if dzx == -1 then 0.00001 else 1
        ssy = if dzy == -1 then 0.00001 else 1
        @scaleInternal @sel, ssx, ssy
        @scaleInternal @sel, dzx, dzy
        @sel.pzx = zx
        @sel.pzy = zy

      w = @sel.bounds.width
      h = @sel.bounds.height

      sx = Math.abs(1 + @sel.pzx * event.delta.x / w)
      sy = Math.abs(1 + @sel.pzy * event.delta.y / h)

      return if sx is 0 or sy is 0

      @scaleInternal @sel, sx, sy

      # redraw selection rect, we do not scale it because we need selectRect strokeWidth to stay unchanged
      @sel.selectionRect.remove()
      @sel.selectionRect = @createSelRect()

    ###oldPoint = @sel.oldPoint
    delta = new Point(event.point.x - oldPoint.x, event.point.y - oldPoint.y)

    w = event.point.x - @sel.center.x
    h = event.point.y - @sel.center.y

    if -3 < w < 3 or -3 < h < 3
      return
    else
      @sel.oldPoint = event.point

    sx = 1 + delta.x / w
    sy = 1 + delta.y / h###

    scaleInternal: (item, sx, sy) ->
      item.transform new Matrix().scale(sx, sy, item.center)
      item.arrowGroup.drawTriangle() if item.arrowGroup

    # ITEMS MISC
    createUserBadge: (uid, x, y) ->
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
      return true unless item
      return false unless item.segments
      return true if item.segments.length is 1
      if item.segments.length is 2
        segmentsAreEqual = item.segments[0].point.x is item.segments[1].point.x and item.segments[0].point.y is item.segments[1].point.y
        return segmentsAreEqual
      return false

    insertFirst: (item) ->
      paper.project.activeLayer.insertChild(0, item)

    drawArrow: (arrowLine) ->
      arrowGroup = new Group([arrowLine])
      arrowGroup.arrow = arrowLine
      arrowGroup.drawTriangle = => @drawArrowTriangle arrowGroup
      arrowGroup.triangle = arrowGroup.drawTriangle()
      @init arrowGroup.triangle
      @created = arrowLine
      arrowLine.arrowGroup = arrowGroup

    drawArrowTriangle: (group) ->
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
