$ ->
  home =
    showLogin: ->
      $("#loginBlock").css(
        position: 'absolute'
        top: $("#header").height() + 5
        left: $("#signInButton").offset().left - $("#loginBlock").width() + 40
      ).fadeIn()

      $(document).on "click.login", ->
        target = event.target
        return if target.id == "loginBlock" or target.id == "signInButton" or $(target).closest("#loginBlock")[0]
        $("#loginBlock").fadeOut()

      return false

    initLogin: ->
      $("#loginForm").data "process-submit", (data) -> home.processLogin(data)

    processLogin: (data) ->
      if data == "OK" then window.location = "/" else $("#loginError").show().html(data.message)

  home.initLogin()
  App.Home = home


