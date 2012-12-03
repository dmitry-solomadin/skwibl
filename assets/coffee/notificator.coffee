$ ->
  class Notificator
    constructor: ->
      @notification = $("<div id='notification' class='notification'></div>")
      @notification.hide()
      $("body").append(@notification)

    notify: (text) ->
      @notification.html(text)
      @show()

    show: ->
      @notification.css({right: 50, top: 30})
      @notification.show()
      @notification.animate
        opacity: 1
        top: 60, ->
          callback = -> App.notificator.hide()
          window.setTimeout(callback, 2000)

    hide: ->
      @notification.animate {opacity: 0}, -> $(@).hide()

  App.notificator = new Notificator
