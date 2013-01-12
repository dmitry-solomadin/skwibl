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
      console.log 'remove'
      return unless item
      room.history.add(
        actionType: "remove"
        tool: item #TODO change tool to item
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

    pan: (delta) ->
      #TODO move history logic out of this method
      console.log 'pan'
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

        @sel.selectedScaler = null
        for sn, scaler of rect.scalers
          if scaler.bounds.contains point
            @sel.selectedScaler = scaler

        if rect.removeButton?.bounds.contains(point)
          @remove()

    createSelRect: ->
#       console.log 'create sel'
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

      nw.zone = {zx: -1, zy: -1, xb: bounds.right, yb: bounds.bottom, opposite: "bottomRight", oppositeScaler: se}
      se.zone = {zx: 1, zy: 1, xb: bounds.left, yb: bounds.top, opposite: "topLeft", oppositeScaler: nw}
      ne.zone = {zx: 1, zy: -1, xb: bounds.left, yb: bounds.bottom, opposite: "bottomLeft", oppositeScaler: sw}
      sw.zone = {zx: -1, zy: 1, xb: bounds.right, yb: bounds.top, opposite: "topRight", oppositeScaler: ne}

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

      selectedScaler = @sel.selectedScaler
      zx = selectedScaler.zone.zx
      zy = selectedScaler.zone.zy

      # item x and y bounds, crossing this bounds will affect in zone change
      xb = selectedScaler.zone.xb
      yb = selectedScaler.zone.yb

      # Delta zone. -1 indicates that zone (x/y) has changed +1 indicates that zone (x/y) left unchanged
      dzx = if (zx > 0 and event.point.x < xb) or (zx < 0 and event.point.x > xb) then -1 else 1
      dzy = if (zy > 0 and event.point.y < yb) or (zy < 0 and event.point.y > yb) then -1 else 1

      unless dzx == 1 and dzy == 1
        # calculate new zone
        nzx = zx * dzx
        nzy = zy * dzy

        # find right scaler by zone
        for sn, scaler of @sel.selectionRect.scalers
          if scaler.zone.zx == nzx and scaler.zone.zy == nzy
            @sel.selectedScaler = scaler
            break

        ssx = if dzx == -1 then -0.00001 else 1
        ssy = if dzy == -1 then -0.00001 else 1

        #Make sure that no matter has fast user mouse moves we make the item small as possible before reflecting it
        @scaleInternal @sel, ssx, ssy, selectedScaler.zone.opposite
        #Reflect the item
        @scaleInternal @sel, dzx, dzy, @sel.selectedScaler.zone.opposite

      w = @sel.bounds.width
      h = @sel.bounds.height

      sx = Math.abs(1 + zx * event.delta.x / w)
      sy = Math.abs(1 + zy * event.delta.y / h)
      return unless sx and sy

      @scaleInternal @sel, sx, sy, @sel.selectedScaler.zone.opposite

      # redraw selection rect, we do not scale it because we need selectRect strokeWidth to stay unchanged
      @sel.selectionRect.remove()
      @sel.selectionRect = @createSelRect()

    scaleInternal: (item, sx, sy, anchorPointName) ->
      anchorPoint = if item.arrow then item.arrow.bounds[anchorPointName] else item.bounds[anchorPointName]
      transformMatrix = new Matrix().scale(sx, sy, anchorPoint)
      if item.arrow
        item.arrow.transform transformMatrix
        item.drawTriangle()
      else
        item.transform transformMatrix

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
      @init(triangle)
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
