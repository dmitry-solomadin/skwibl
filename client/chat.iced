$ ->
  return unless currentPage "projects/room/show"

  class Chat
    constructor: ->
      @users = []
      for chatUser in $(".chatUser")
        @users.push
          id: $(chatUser).data("uid")
          displayName: $(chatUser).data("display-name")
          picture: $(chatUser).data("picture")

      @initCarousel()
      @initSockets()

      # when the client clicks SEND
      $('#chatsend').click =>
        @sendMessage()
        $('#chattext').focus()

      # when the client hits ENTER on the keyboard
      $('#chattext').keypress (e) =>
        if e.which is 13
          @sendMessage()
          false

      $("#chatFilters button").click ->
        tab = $(@).data('tab')
        $("#chatFilters button").removeClass("active")
        $(@).addClass("active")
        $(".tab-content").hide()
        $("#" + tab).show()

      $("#chat").data("visible", "true")
      @scrollToTheBottom()

    initCarousel: ->
      new App.SkwiblCarousel
        selector: '.project_participants_slider_container'
        height: 45
        leftArrowClass: "project_participants_slider_l"
        rightArrowClass: "project_participants_slider_r"

    addNewUser: (user) ->
      @users.push user

      picture = user.picture or '/images/avatar.png'

      $("#participants").append("<div class='chatUser' id='chatUser#{user.id}' data-uid='#{user.id}'
                                                              data-display-name='#{user.displayName}' data-picture='#{picture}'>
                                                              <img class='userAvatar tooltipize' src='#{picture}' width='48' title='#{user.displayName}'/>
                                                              </div>")

    isVisible: ->
      $("#chat").data("visible") is "true"

    fold: ->
      $("#chat").data("visible", "false")
      $("#chat").animate {left: -305}, queue: false
      $("#canvasFooter").animate(paddingLeft: 0)
      $(".canvasFooterInner").animate {width: $(window).width()}, ->
        $(".canvasFooterInner").css(width: "100%")
        $('#canvasSelectDiv')[0].carousel.update()

      $("#chatFolder").attr("onclick", "App.chat.unfold(this); return false;")

    unfold: ->
      $("#chat").data("visible", "true")
      $("#chat").animate {left: 0}, queue: false
      $("#canvasFooter").animate(paddingLeft: 300)
      $(".canvasFooterInner").animate {width: $(window).width() - 300}, =>
        $(".canvasFooterInner").css(width: "100%")
        $('#canvasSelectDiv')[0].carousel.update()
        unfoldCallback = @getChatUnfoldCallback()
        unfoldCallback() if unfoldCallback

      $("#chatFolder").attr("onclick", "App.chat.fold(this); return false;")
      @clearBadgeCount()
      @scrollToTheBottom()

    getChatUnfoldCallback: () ->
      @unfoldCallback.pop() if @unfoldCallback

    setChatUnfoldCallback: (callback) ->
      @unfoldCallback = []
      @unfoldCallback.push(callback)

    getUserById: (uid) ->
      for user in @users
        return user if "#{user.id}" is "#{uid}"

    addBadgeCount: ->
      $("#chatBadge").show().html(parseInt($("#chatBadge").html()) + 1)

    clearBadgeCount: ->
      $("#chatBadge").hide().html("0")

    addMessage: (uid, message) ->
      @addBadgeCount() unless @isVisible()

      user = @getUserById(uid)

      chatMessage = $(".messageTemplate").clone().removeClass("messageTemplate").show()
      chatMessage.find(".messageAuthor").html(user.displayName + ":")
      chatMessage.find(".messageText").html(message)
      chatMessage.find(".image img").attr("src", user.picture)
      chatMessage.find(".timestamp").html(moment(Date.now()).format("HH:mm"))

      # let's see if we would need to scroll to the bottom after adding the message
      # we need to scroll if the adding user is current or the chat hasn't been scrolled
      conversation = $("#conversation-inner")
      scrollToTheBottom = "#{uid}" is "#{$("#uid").val()}" or (conversation[0].scrollTop + conversation.innerHeight()) is conversation[0].scrollHeight

      $('#conversation-inner .today').append(chatMessage)

      @scrollToTheBottom() if scrollToTheBottom

    scrollToTheBottom: ->
      $("#conversation-inner").scrollTop($("#conversation-inner")[0].scrollHeight)

    addTechMessage: (message) ->
      $('#conversation-inner .today').append("<div>#{message}</div>")

    changeUserStatus: (uid, online) ->
      chatStatus = $("#chatUserStatus#{uid}")
      if online
        chatStatus.addClass("chatUserOnline").removeClass("chatUserOffline")
      else
        chatStatus.addClass("chatUserOffline").removeClass("chatUserOnline")

    sendMessage: ->
      chatMessage =
        msg: $('#chattext').val()
        elementId: App.room.generateId()
      $('#chattext').val("")
      return if $.trim(chatMessage.msg).length is 0
      App.chat.addMessage($("#uid")[0].value, chatMessage.msg)
      App.chat.chatIO.emit("message", chatMessage)

    removeUser: (uid) ->
      for user, index in @users
        @users.splice(index, 1) if "#{user.id}" is "#{uid}"
      $("#chatUser#{uid}").remove()

    showMessageRange: (showRangeLink) ->
      rangeId = $(showRangeLink).data("range-id")

      if rangeId is 'all'
        $(".timeRange").show()
        $(".showRangeLink, .pipe").hide()
      else
        $("." + rangeId).show().next(".timeRange").show()
        $(showRangeLink).hide().next(".pipe:first").hide()
        $(showRangeLink).prevAll(".showRangeLink, .pipe").hide()
      $(".earlierMessagesHeader").html("No Earlier Messages") if $(".showRangeLink:visible").length is 0

    initSockets: ->
      @chatIO = io.connect('/chat', window.copt)

      @chatIO.on 'message', (data) =>
        @addMessage(data.id, data.message.msg)

      @chatIO.on 'userRemoved', (uid) =>
        if "#{uid}" is "#{$("#uid").val()}"
          window.location.reload()
        else
          @removeUser uid

      @chatIO.on 'enter', (user) =>
        @addNewUser user unless @getUserById user.id

        @changeUserStatus user.id, true
        @addTechMessage("<i>#{user.displayName} entered the project</i>")

      @chatIO.on 'exit', (uid) =>
        @changeUserStatus uid, false
        user = @getUserById uid
        @addTechMessage("<i>#{user.displayName} left the project</i>")

      @chatIO.on 'onlineUsers', (uids) =>
        @changeUserStatus(uid, true) for uid in uids

  App.chat = new Chat
