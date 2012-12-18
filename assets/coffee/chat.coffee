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

      # when the client clicks SEND
      $('#chatsend').click =>
        @sendMessage()
        $('#chattext').focus()

      # when the client hits ENTER on the keyboard
      $('#chattext').keypress (e) =>
        if e.which is 13
          @sendMessage()
          false

      $("#chatFilters a").click ->
        $("#chatFilters a").removeClass("active")
        $(@).addClass("active")
        $("#conversation-inner .tab-content").hide()
        $("##{$(@).data('tab')}").show()

      $("#chat").data("visible", "true")

    addNewUser: (user) ->
      @users.push user

      picture = if user.picture then user.picture else '/images/avatar.png'

      $("#participants").append("<div class='chatUser' id='chatUser#{user.id}' data-uid='#{user.id}'
            data-display-name='#{user.displayName}' data-picture='#{picture}'>
            <img class='userAvatar tooltipize' src='#{picture}' width='48' title='#{user.displayName}'/>
            <span class='chatUserStatus'></span>
            </div>")

    isVisible: ->
      $("#chat").data("visible")

    fold: (link) ->
      $("#chat").data("visible", "false")
      $("#chat").animate(left: -305)
      $("#header-foldable").animate(width: 200)
      $("#canvasFooter").animate(paddingLeft: 0)
      $(".canvasFooterInner").animate({width: $(window).width()}, -> $(".canvasFooterInner").css(width: "100%"))

      $(link).attr("onclick", "App.chat.unfold(this); return false;").find("img").attr("src", "/images/room/unfold.png")

    unfold: (link) ->
      $("#chat").data("visible", "true")
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

    sendMessage: ->
      chatMessage =
        element:
          msg: $('#chattext').val()
          elementId: App.room.generateId()

      $('#chattext').val("")

      return if $.trim(chatMessage.element.msg).length == 0

      App.chat.addMessage($("#uid")[0].value, chatMessage.element.msg)
      App.chat.chatIO.emit("message", chatMessage)

    initSockets: ->
      @chatIO = io.connect('/chat', window.copt)

      @chatIO.on 'message', (data) => @addMessage(data.id, data.message.element.msg)

      @chatIO.on 'enter', (user) =>
        @addNewUser user if not @getUserById user.id

        @changeUserStatus user.id, true
        @addTechMessage("<i>#{user.displayName} entered the project</i>")

      @chatIO.on 'exit', (uid) =>
        @changeUserStatus uid, false
        user = @getUserById uid
        @addTechMessage("<i>#{user.displayName} left the project</i>")

      @chatIO.on 'onlineUsers', (uids) => @changeUserStatus(uid, true) for uid in uids

  App.chat = new Chat

