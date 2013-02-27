$ ->
  class Util

    constructor: ->
      @emailRegexp = /[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?/

    isEmailValid: (email)->
      return @emailRegexp.test email

  $.fn.combinedHover = (settings) ->
    trigger = this
    additionalTriggers = settings.additionalTriggers

    trigger[0].hovercount = 0

    updateHoverCount = (toAdd) -> trigger[0].hovercount = trigger[0].hovercount + toAdd
    addHoverCount = -> updateHoverCount(1)
    removeHoverCount = ->
      updateHoverCount(-1)
      offTrigger = -> settings.offTrigger() if trigger[0].hovercount is 0
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

    $(document).on "mousemove touchmove", (e) =>
      return unless @hasClass "draggable"

      if e.type is "touchmove"
        touches = event.changedTouches
        first = touches[0]
        point = {x: first.clientX, y:first.clientY}
      else
        point = {x: e.clientX, y:e.clientY}

      unless @data("pdx")
        @data("pdx", point.x)
        @data("pdy", point.y)
      else
        dx = point.x - parseInt(@data("pdx"))
        dy = point.y - parseInt(@data("pdy"))

        @data("pdx", point.x)
        @data("pdy", point.y)

        opt.onDrag(dx, dy)

    $(document).on "mouseup touchend", (e) =>
      return unless @hasClass "draggable"

      draggedObject = $('.draggable')
      if draggedObject[0] and opt.onAfterDrag
        opt.onAfterDrag(draggedObject[0])

      draggedObject.removeClass('draggable')

    @css('cursor', opt.cursor).on "mousedown touchstart", (e) =>
      @addClass('draggable')
      @data("pdx", "")
      @data("pdy", "")
      e.preventDefault()

    this

  $(document).bind 'ajaxSend', (e, request, options) ->
    $('[data-loading]').each ->
      $(@).attr("disabled","disabled")
      $(@).data("prevText", $(@).html())
      $(@).html($(@).data("loading"))

  $(document).bind 'ajaxComplete', (e, request, options) ->
    $('[data-loading]').each ->
      $(@).removeAttr("disabled")
      $(@).html($(@).data("prevText"))

  App.Util = new Util

window.isMac = -> return /Mac/.test(navigator.userAgent)

window.currentPage = (template) -> return $("#currentTemplate").val() is template

window.hasAjaxError = ->
  for ajaxError in $(".error_ajax")
    return true if $(ajaxError).css("visibility") is "visible"
  return false





