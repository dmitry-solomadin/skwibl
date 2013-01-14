$ ->
  class Home

    constructor: ->
      $(".tooltipize").tooltip()

      $("#forgotpasswordlink").click => @showForgotPassword()
      $("#backToLogin").click => @hideForgotPassword()
      $("#submitForgotPassword").click => @submitForgotPassword()
      $("#loginForm").data "process-submit", (data) => @processLogin(data)

      $(".banner_nav a").on "click", ->
        $(".banner_nav a").removeClass("selected")
        $(@).addClass("selected")
        false

    showLogin: ->
      $("#loginBlock").show().css(
        position: 'absolute'
        top: $("#header").height() - 500
        left: $("#signInButton").offset().left - $("#loginBlock").width() + 95
      ).animate(
        top: $("#header").height() - 5
      , 400)

      $(document).on "click.login", (event) ->
        target = event.target
        return if target.id is "loginBlock" or target.id is "signInButton" or $(target).closest("#loginBlock")[0]
        $("#loginBlock").animate
          top: $("#header").height() - 500, 400

      return false

    showForgotPassword: ->
      $(".loginBlockWrapper > form:first").animate(left: -300)
      $(".loginBlockWrapper > form:last").animate(left: -300)

    hideForgotPassword: ->
      $(".loginBlockWrapper > form:first").animate(left: 0)
      $(".loginBlockWrapper > form:last").animate(left: 0)

    submitForgotPassword: ->
      email = $("#forgotPasswordEmail").val()
      $("#forgotPasswordError")[0].className = ""
      $("#forgotPasswordError").html("Sending...")
      $.post '/forgotpassword', {email: email}, (data, status, xhr) ->
        if data
          $("#forgotPasswordError")[0].className = "textSuccess"
          $("#forgotPasswordError").html("New password has been sent to this email.")
        else
          $("#forgotPasswordError")[0].className = "textError"
          $("#forgotPasswordError").html("We don't have this email.")

    processLogin: (data) ->
      $("#loginError").html("")
      if data is "OK"
        window.location = "/"
      else
        $("#loginError")[0].className = "textError"
        $("#loginError").html(data.message)

    facebookAuth: ->
      win = window
      window.onFacebookSuccess = -> win.location.reload()
      window.open "/auth/facebook", "", "width=1000,height=600,left=100,top=100,resizable=yes,scrollbars=yes,status=yes"

    App.Home = new Home
