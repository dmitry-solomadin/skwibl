$ ->
  class NavDropdown

    constructor: ->
      @DEFAULT_DURATION = 400

      self = @
      for toggler in $("[data-dropdown-toggler]")
        dropdown = $("#" + $(toggler).data("dropdown-toggler"))
        dropdown.css
          left: $(toggler).offset().left - $(dropdown).width() + $(toggler).width()
          top: -$(dropdown).height()

      $("[data-dropdown-toggler]").click ->
        dropdownId = $(@).data("dropdown-toggler")
        duration = $(@).data("duration") or self.DEFAULT_DURATION
        self.show dropdownId, duration if not $("##{dropdownId}:visible")[0]

    show: (dropdownId, duration)->
      dropdown = $("##{dropdownId}")
      dropdown.show().animate top: $("#header").height() - 5, duration

      $(document).on "click.login", (event) =>
        target = event.target
        return if target.id is dropdownId or $(target).closest("##{dropdownId}")[0]
        $(document).off "click.login"
        @hide dropdownId, duration

      return false

    hide: (dropdownId, duration) ->
      dropdown = $("##{dropdownId}")
      dropdown.animate top: -$(dropdown).height(), duration, -> $(@).hide()

  App.NavDropdown = new NavDropdown()