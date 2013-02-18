$ ->
  class App.SkwiblCarousel

    constructor: (settings) ->
      @settings = settings
      @carousel = $(@settings.selector)
      @carouselParent = @carousel.parent()
      @initialize()
      @carousel[0].carousel = @

    initialize: ->
      @carousel.addClass("skwibl-carousel")
      @carousel.css
        width: "4000px" # this might be not good enough, think about better way
        height: @settings.height

      @carouselWrap = $("<div class='skwibl-carousel-wrap'></div>")
      @carouselWrap.width(@availableWidth()).height(@settings.height)
      @carousel.wrap @carouselWrap
      @carouselWrap = @carousel.parent()

      @carouselLeft = $("<div class='skwibl-carousel-l'></div>")
      @carouselRight = $("<div class='skwibl-carousel-r'></div>")
      @carouselLeft.addClass(@settings.leftArrowClass) if @settings.leftArrowClass
      @carouselRight.addClass(@settings.rightArrowClass) if @settings.rightArrowClass
      @carouselParent.prepend(@carouselLeft)
      @carouselParent.append(@carouselRight)

      @lArrWidth = @carouselLeft.outerWidth(true)
      @rArrWidth = @carouselRight.outerWidth(true)

      @toggleArrows()
      @carouselWrap.width @availableWidth()

      fastForward = (invisible, forward) =>
        # todo queue up the animations
        return if @carousel.queue("fx").length > 0
        length = 0
        length += $(child).outerWidth(true) for child in invisible
        length = -length if forward
        currentLength = parseInt(@carousel.css("left"))
        length = currentLength + length
        @carousel.animate {left: length}, "fast"

      fakeFastForward = (forward) =>
        return if @carousel.queue("fx").length > 0
        currentLength = parseInt(@carousel.css("left"))
        amount = if forward then -20 else 20
        length = currentLength + amount
        @carousel.animate {left: length}, "fast", => @carousel.animate {left: currentLength}

      @carouselLeft.on "click", =>
        firstVisibleIndex = @firstVisible().index()
        if firstVisibleIndex is 0
          fakeFastForward(false)
        else
          from = if firstVisibleIndex - 2 < 0 then 0 else firstVisibleIndex - 2
          invisible = @carousel.children()[from..firstVisibleIndex - 1]
          fastForward(invisible, false)

      @carouselRight.on "click", =>
        lastVisibleIndex = @lastVisible().index()
        if lastVisibleIndex is (@carousel.children().length - 1)
          fakeFastForward(true)
        else
          invisible = @carousel.children()[lastVisibleIndex + 1..lastVisibleIndex + 2]
          fastForward(invisible, true)

    goToItem: (number, center) ->
      availableWidth = @availableWidth()
      for i in [number..0]
        availableWidth -= $(@carousel.children()[i]).outerWidth(true)
        break if availableWidth < 0
        prevChild = $(@carousel.children()[i])
      if not prevChild[0] then alert("something wierd happened!")
      @carousel.animate({left: -prevChild.position().left}, "fast")

    update: ->
      @toggleArrows()
      @carouselWrap.width @availableWidth()
      @carousel.css("left", 0) if not @areArrowsVisible()
      if @areArrowsVisible() and @visibleChildrenWidth() < @availableWidth()
        @goToItem(@carousel.children().length - 1)

    toggleArrows: ->
      arrs = @carouselParent.find(".skwibl-carousel-l, .skwibl-carousel-r")
      if @childrenWidth() < @carouselParent.width()
        arrs.hide()
        @carouselWrap.css("marginLeft", 0)
      else
        arrs.show()
        @carouselWrap.css("marginLeft", $(arrs[0]).outerWidth(true))

    areArrowsVisible: ->
      @carouselParent.find(".skwibl-carousel-l:visible, .skwibl-carousel-r:visible").length is 2

    availableWidth: ->
      arrowsWidth = if @areArrowsVisible() then @lArrWidth + @rArrWidth else 0
      availableWidth = 0
      fullWidth = @carouselParent.width() - arrowsWidth
      for child in @carousel.children()
        tempAvailableWidth = availableWidth
        tempAvailableWidth += $(child).outerWidth(true)
        break if tempAvailableWidth > fullWidth
        availableWidth = tempAvailableWidth
      availableWidth

    childrenWidth: ->
      childrenWidth = 0
      for child in @carousel.children()
        childrenWidth += $(child).outerWidth(true)
      childrenWidth

    visibleChildrenWidth: ->
      childrenWidth = 0
      for child in @carousel.children()[@firstVisible().index()..@lastVisible().index()]
        childrenWidth += $(child).outerWidth(true)
      childrenWidth

    firstVisible: ->
      left = Math.abs(parseInt(@carousel.css("left")))
      for child in @carousel.children()
        left -= $(child).outerWidth(true)
        return $(child) if left < 0
      return null

    lastVisible: ->
      width = @availableWidth()
      firstVisibleIndex = if @firstVisible() then @firstVisible().index() else 0
      children = @carousel.children()
      for child, i in children when i >= firstVisibleIndex
        width -= $(child).outerWidth(true)
        return prevChild if width < 0
        prevChild = $(child)
      $(children[children.length - 1])


