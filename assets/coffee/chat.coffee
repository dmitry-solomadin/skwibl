$ ->
  return unless currentPage "projects/show"

  class Chat
    constructor: ->
      @users = []
      @initSockets()

    fold: (link) ->
      $("#chat").animate(left: -305)
      $("#header-foldable").animate(width: 125)
      $("#canvasFooter").animate(paddingLeft: 0)
      $(".canvasFooterInner").animate({width: $(window).width()}, -> $(".canvasFooterInner").css(width: "100%"))

      $(link).attr("onclick", "App.chat.unfold(this); return false;").html(">>")

    unfold: (link) ->
      $("#chat").animate(left: 0)
      $("#header-foldable").data("width", $("#header-foldable").width())
      $("#header-foldable").animate(width: 280)
      $("#canvasFooter").animate(paddingLeft: 300)
      $(".canvasFooterInner").animate({width: $(window).width() - 300}, -> $(".canvasFooterInner").css(width: "100%"))

      $(link).attr("onclick", "App.chat.fold(this); return false;").html("<<")

    getUserById: (id) ->
      for user in @users
        return user if user.id == id

    updateUsers: ->
      $('#participants').empty()
      $.each @users, (key, val) ->
        if val.status == 'online'
          $('#participants').append("<div>#{val.id} : #{val.displayName} online</div>")
        else
          $('#participants').append("<div>#{val.id} : #{val.displayName} offline</div>")

    addMessage: (id, message) ->
      $('#conversation-inner').append("<b>#{id}:</b> #{message}<br>")

    initSockets: ->
      @chatIO = io.connect('/chat', window.copt)
      @chatIO.on 'connect', -> console.log('connect')
      @chatIO.on 'connecting', -> console.log('connecting')
      @chatIO.on 'connect_failed', -> console.log('connect_failed')
      @chatIO.on 'disconnect', -> console.log('disconnect')
      @chatIO.on 'reconnect', -> console.log('reconnect')
      @chatIO.on 'reconnecting', -> console.log('reconnecting')
      @chatIO.on 'reconnect_failed', -> console.log('reconnect_failed')
      @chatIO.on 'error', -> console.log('error')

      @chatIO.on 'message', (data, cb) ->
        $('#conversation-inner').append("<b>#{data.id}:</b> #{data.message}<br>")

      @chatIO.on 'enter', (id, cb) =>
        user = @getUserById(id)
        user.status = 'online'
        @updateUsers()
        @addMessage(id, "<i>User #{id} : #{user.displayName} entered the project</i>")

      @chatIO.on 'exit', (id, cb) =>
        user = @getUserById(id)
        delete user.status
        @updateUsers()
        @addMessage(id, "<i>User #{id} : #{user.displayName} leave the project</i>")

      @chatIO.on 'users', (data) =>
        @users = data
        @updateUsers()

      @chatIO.on 'messages', (data) =>
        $('#conversation-inner').empty()
        @addMessage(val.owner, val.data) for val in data

  # when the client clicks SEND
  $('#chatsend').click ->
    message = $('#chattext').val()
    $('#chattext').val('').focus()
    if message != ''
      console.log(App.chat)
      App.chat.addMessage($("#uid")[0].value, message)
      App.chat.chatIO.send(message)

  # when the client hits ENTER on the keyboard
  $('#chattext').keypress (e) ->
    if e.which == 13
      $(@).blur()
      $('#chatsend').focus().click()

  App.chat = new Chat
