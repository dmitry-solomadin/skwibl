$ ->
  class App.SkwiblMenu

    MAX_WIDTH: 1065

    constructor: (settings) ->
      @settings = settings
      @init()

    init: ->
      $(window).resize =>
        @update()

      @addMenu = $("#skwiblAdditionalMenu")


      $(hideable).removeAttr("data-overflow-hideable").show() for hideable in @addMenu.find("ul").children()

      @update()

    update: ->
      hideables = $("[data-overflow-hideable='true']")
      panelWidth = @settings.menu.parent().width()
      if panelWidth < @MAX_WIDTH
        $("#menuShowMore").show()
        @addMenu.find("ul").append(hideables)
      else
        $("#menuShowMore").hide().removeClass("selected")
        @settings.menu.append(hideables)
        $("#skwiblAdditionalMenu")[0].drpdwn.hide()
