$ ->
  return unless currentPage "projects/show"

  class Chat
    constructor: ->
      @users = []
      for chatUser in $(".chatUser")
        @users.push
          id: $(chatUser).data("uid")
          displayName: $(chatUser).data("display-name")
          picture: $(chatUser).data("picture")

      @initSockets()

      $("#chatFilters a").click ->
        $("#chatFilters a").removeClass("active")
        $(@).addClass("active")
        $("#conversation-inner .tab-content").hide()
        $("##{$(@).data('tab')}").show()

    fold: (link) ->
      $("#chat").animate(left: -305)
      $("#header-foldable").animate(width: 200)
      $("#canvasFooter").animate(paddingLeft: 0)
      $(".canvasFooterInner").animate({width: $(window).width()}, -> $(".canvasFooterInner").css(width: "100%"))

      $(link).attr("onclick", "App.chat.unfold(this); return false;").find("img").attr("src", "/images/room/unfold.png")

    unfold: (link) ->
      $("#chat").animate(left: 0)
      $("#header-foldable").data("width", $("#header-foldable").width())
      $("#header-foldable").animate(width: 280)
      $("#canvasFooter").animate(paddingLeft: 300)
      $(".canvasFooterInner").animate({width: $(window).width() - 300}, -> $(".canvasFooterInner").css(width: "100%"))

      $(link).attr("onclick", "App.chat.fold(this); return false;").find("img").attr("src", "/images/room/fold.png")

    getUserById: (uid) ->
      for user in @users
        return user if `user.id == uid`

    addMessage: (uid, message) ->
      user = @getUserById(uid)
      $('#conversation-inner #chat-tab').append("<div><b>#{user.displayName}:</b> #{message}</div>")

    addTechMessage: (message) ->
      $('#conversation-inner #chat-tab').append("<div>#{message}</div>")

    changeUserStatus: (uid, online) ->
      chatStatus = $("#chatUser#{uid}").find(".chatUserStatus")
      if online
        chatStatus.addClass("chatUserOnline").removeClass("chatUserOffline")
      else
        chatStatus.addClass("chatUserOffline").removeClass("chatUserOnline")

    initSockets: ->
      @chatIO = io.connect('/chat', window.copt)

      @chatIO.on 'message', (data, cb) => @addMessage(data.id, data.message.element.msg)

      @chatIO.on 'enter', (uid, cb) =>
        @changeUserStatus uid, true
        user = @getUserById uid
        @addTechMessage("<i>#{user.displayName} entered the project</i>")

      @chatIO.on 'exit', (uid, cb) =>
        @changeUserStatus uid, false
        user = @getUserById uid
        @addTechMessage("<i>#{user.displayName} leaved the project</i>")

      @chatIO.on 'onlineUsers', (uids) => @changeUserStatus(uid, true) for uid in uids

  # when the client clicks SEND
  $('#chatsend').click ->
    chatMessage =
      element:
        msg: $('#chattext').val()
        elementId: App.room.generateId()

    $('#chattext').val('').focus()
    unless chatMessage.element.msg is ''
      App.chat.addMessage($("#uid")[0].value, chatMessage.element.msg)
      App.chat.chatIO.emit("message", chatMessage)

  # when the client hits ENTER on the keyboard
  $('#chattext').keypress (e) ->
    if e.which == 13
      $(@).blur()
      $('#chatsend').focus().click()

  App.chat = new Chat

