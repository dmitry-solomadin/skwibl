$ ->
  class App.SkwiblCarousel

    defaults:
      adjustPaddings: false
      itemPartialVisibility: false

    constructor: (settings) ->
      @settings = $.extend {}, @defaults, settings
      @carousel = $(@settings.selector)
      @carouselParent = @carousel.parent()
      @carousel[0].carousel = @
      @initialize()

    initialize: ->
      @carousel.addClass("skwibl-carousel")
      @carousel.css
        width: "4000px" # this might be not good enough, think about better way
        height: @settings.height

      @carouselWrap = $("<div class='skwibl-carousel-wrap'></div>")
      @carouselWrap.width(@availableWidth()).height(@settings.height)
      @carousel.wrap @carouselWrap
      @carouselWrap = @carousel.parent()

      @carouselLeft = $("<div class='skwibl-carousel-l noselect'></div>")
      @carouselRight = $("<div class='skwibl-carousel-r noselect'></div>")
      @carouselLeft.addClass(@settings.leftArrowClass) if @settings.leftArrowClass
      @carouselRight.addClass(@settings.rightArrowClass) if @settings.rightArrowClass
      @carouselParent.prepend(@carouselLeft)
      @carouselParent.append(@carouselRight)

      @lArrWidth = @carouselLeft.outerWidth(true)
      @rArrWidth = @carouselRight.outerWidth(true)

      @update()

      $(window).resize =>
        @update()

      fastForward = (invisible, forward) =>
        # todo queue up the animations
        return if @carousel.queue("fx").length > 0
        console.log @startPartialVisible()
        console.log @endPartialVisible()

        length = 0
        length += $(child).outerWidth(true) for child in invisible
        if forward then length -= @endPartialVisible() else length -= @startPartialVisible()
        length = -length if forward

        currentLength = parseInt(@carousel.css("left"))
        resultingLength = currentLength + length
        if not forward and resultingLength > 0 then resultingLength = 0
        @carousel.animate {left: resultingLength}, "fast"

      fakeFastForward = (forward) =>
        return if @carousel.queue("fx").length > 0
        currentLength = parseInt(@carousel.css("left"))
        amount = if forward then -20 else 20
        length = currentLength + amount
        @carousel.animate {left: length}, "fast", =>
          @carousel.animate {left: currentLength}

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
          invisible = @carousel.children()[lastVisibleIndex+1..lastVisibleIndex + 2]
          fastForward(invisible, true)

    goToItem: (number, onFinish) ->
      availableWidth = @availableWidth()
      for i in [number..0]
        availableWidth -= $(@carousel.children()[i]).outerWidth(true)
        break if availableWidth < 0
        prevChild = $(@carousel.children()[i])
      if not prevChild[0] then alert("something wierd happened!")
      @carousel.animate {left: -prevChild.position().left}, "fast", ->
        onFinish() if onFinish

    update: ->
      updateInternal = =>
        @adjustDefaultPaddings() if @settings.adjustPaddings
        @toggleArrows()
        @adjustPaddings() if @settings.adjustPaddings
        @carouselWrap.width @availableWidth()
        @carousel.css("left", 0) if not @areArrowsVisible()

      # this will be true if updated after user removed last item in carousel we then need shift items to the right
      moreSpaceAvailable = @areArrowsVisible() and @visibleChildrenWidth() < @availableWidth()
      # todo implement itemCountDiminished currently deletion of list item in carousel won't work
      itemCountDiminished = false
      if moreSpaceAvailable and itemCountDiminished
        lastItemIndex = @carousel.children().length - 1
        @goToItem lastItemIndex, updateInternal
      else
        updateInternal()

    adjustDefaultPaddings: ->
      for child in @carousel.children() when $(child).data("initial-margin")
        marginRight = parseFloat $(child).data("initial-margin")
        $(child).css "margin-right", marginRight

    adjustPaddings: ->
      return unless @areArrowsVisible()
      adjustWidth = @fullWidth() - @visibleChildrenWidth()
      paddingAdjust = Math.floor(adjustWidth / @visibleItemsCount())
      for child in @carousel.children()
        if $(child).data("initial-margin")
          marginRight = parseFloat($(child).data("initial-margin"))
        else
          marginRight = parseFloat($(child).css("margin-right"))
          $(child).data("initial-margin", marginRight)

        $(child).css("margin-right", marginRight + paddingAdjust)

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
      return @fullWidth() if @settings.itemPartialVisibility

      fullWidth = @fullWidth()
      availableWidth = 0
      for child in @carousel.children()
        tempAvailableWidth = availableWidth
        tempAvailableWidth += $(child).outerWidth(true)
        break if tempAvailableWidth > (fullWidth + ($(child).outerWidth(true) - $(child).width()))
        availableWidth = tempAvailableWidth
      availableWidth

    fullWidth: ->
      arrowsWidth = if @areArrowsVisible() then @lArrWidth + @rArrWidth else 0
      @carouselParent.width() - arrowsWidth

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

    visibleItemsCount: ->
      @lastVisible().index() - @firstVisible().index()

    firstVisible: ->
      leftEdge = @leftEdge()
      return $(child) for child in @carousel.children() when $(child).position().left >= leftEdge

    startPartialVisible: ->
      leftEdge = @leftEdge()
      for child in @carousel.children()
        childLeft = $(child).position().left
        break if childLeft >= leftEdge
        return (childLeft + $(child).width() - leftEdge) if childLeft < leftEdge and childLeft + $(child).width() > leftEdge
      return 0

    lastVisible: ->
      rightEdge = @rightEdge()
      for child in @carousel.children().get().reverse()
        return $(child) if $(child).position().left + $(child).outerWidth(true) <= rightEdge

    endPartialVisible: ->
      rightEdge = @rightEdge()
      for child in @carousel.children().get().reverse()
        childLeft = $(child).position().left
        break if childLeft + $(child).width() < rightEdge
        return (rightEdge - childLeft) if childLeft < rightEdge and childLeft + $(child).outerWidth(true) > rightEdge
      return 0

    leftEdge: ->
      Math.abs(parseInt(@carousel.css("left")))

    rightEdge: ->
      @leftEdge() + @availableWidth()



