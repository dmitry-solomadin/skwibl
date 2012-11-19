$ ->
  $.fn.combinedHover = (settings) ->
    trigger = this
    additionalTriggers = settings.additionalTriggers

    trigger[0].hovercount = 0

    updateHoverCount = (toAdd) -> trigger[0].hovercount = trigger[0].hovercount + toAdd
    addHoverCount = -> updateHoverCount(1)
    removeHoverCount = ->
      updateHoverCount(-1)
      offTrigger = -> settings.offTrigger() if trigger[0].hovercount == 0
      setTimeout offTrigger, 100

    if settings.live
      $(document).on('mouseenter', additionalTriggers, -> addHoverCount())
        .on('mouseleave', additionalTriggers, -> removeHoverCount())
    else
      additionalTriggers.on('mouseenter', -> addHoverCount())
        .on('mouseleave', -> removeHoverCount())

    trigger.on('mouseenter', ->
      addHoverCount()
      settings.onTrigger()
    ).on('mouseleave', -> removeHoverCount())

  $.fn.valc = ->
    value = @val()
    @val("")
    value

  $.fn.drags = (opt) ->
    opt = $.extend({cursor:"move"}, opt)

    $(document).on "mousemove", (e) =>
      return unless @hasClass "draggable"

      if not @data("pdx")
        @data("pdx", e.clientX)
        @data("pdy", e.clientY)
      else
        dx = e.clientX - parseInt(@data("pdx"))
        dy = e.clientY - parseInt(@data("pdy"))

        @data("pdx", e.clientX)
        @data("pdy", e.clientY)

        opt.onDrag(dx, dy)

    $(document).on "mouseup", (e) =>
      return unless @hasClass "draggable"

      draggedObject = $('.draggable')
      if draggedObject[0] and opt.onAfterDrag
        opt.onAfterDrag(draggedObject[0])

      draggedObject.removeClass('draggable')

    @css('cursor', opt.cursor).on "mousedown", (e) =>
      @addClass('draggable')
      @data("pdx", "")
      @data("pdy", "")
      e.preventDefault()

    this

window.isMac = -> return /Mac/.test(navigator.userAgent)

window.currentPage = (template) -> return $("#currentTemplate").val() == template
