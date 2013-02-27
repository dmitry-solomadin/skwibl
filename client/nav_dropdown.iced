$ ->
  class NavDropdown

    constructor: (toggler) ->
      @DEFAULT_DURATION = 400

      self = @
      @dropdownId = toggler.data("dropdown-toggler")
      @duration = toggler.data("duration") or @DEFAULT_DURATION
      toggler.click ->
        self.show() if not $("##{self.dropdownId}:visible")[0]

    show: ->
      dropdown = $("##{@dropdownId}")
      dropdown.css left: $(dropdown[0].toggler).offset().left - $(dropdown).width() + $(dropdown[0].toggler).width()
      dropdown.show().animate top: $("#header").height(), @duration

      $(document).on "click.login", (event) =>
        target = event.target
        return if target.id is @dropdownId or $(target).closest("##{@dropdownId}")[0]
        $(document).off "click.login"
        @hide()

      return false

    hide: ->
      dropdown = $("##{@dropdownId}")
      dropdown.animate top: -$(dropdown).height(), @duration, -> $(@).hide()

  for toggler in $("[data-dropdown-toggler]")
    drpdwn = new NavDropdown $(toggler)
    dropdown = $("#" + $(toggler).data("dropdown-toggler"))
    dropdown[0].toggler = toggler
    dropdown[0].drpdwn = drpdwn
    dropdown.css
      left: $(toggler).offset().left - $(dropdown).width() + $(toggler).width()
      top: -$(dropdown).height()
