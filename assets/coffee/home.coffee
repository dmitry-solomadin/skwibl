$ ->
  class Home

    constructor: ->
      $("#forgotpasswordlink").click => @showForgotPassword()
      $("#backToLogin").click => @hideForgotPassword()
      $("#submitForgotPassword").click => @submitForgotPassword()
      $("#loginForm").data "process-submit", (data) => @processLogin(data)

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

    showForgotPassword: ->
      $(".loginBlockWrapper > form:first").animate(left: -300)
      $(".loginBlockWrapper > form:last").animate(left: -300)

    hideForgotPassword: ->
      $(".loginBlockWrapper > form:first").animate(left: 0)
      $(".loginBlockWrapper > form:last").animate(left: 0)

    submitForgotPassword: ->
      email = $("#forgotPasswordEmail").val()
      $("#forgotPasswordError").html("")
      $.post '/forgotpassword', {email: email}, (data, status, xhr) ->
        if data
          $("#forgotPasswordError")[0].className = "textSuccess"
          $("#forgotPasswordError").html("New password has been sent to this email.")
        else
          $("#forgotPasswordError")[0].className = "textError"
          $("#forgotPasswordError").html("We don't have this email.")

    processLogin: (data) ->
      if data == "OK" then window.location = "/" else $("#loginError").show().html(data.message)

  App.Home = new Home


