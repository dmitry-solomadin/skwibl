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

    showForgotPassword: ->
      $(".loginBlockWrapper > form:first").animate(left: -335)
      $(".loginBlockWrapper > form:last").animate(left: -335)

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

    submitJoinForm: ->
      $(".error_ajax").css("visibility", "hidden")

      firstName = $("#joinGivenName").val()
      lastName = $("#joinFamilyName").val()
      email = $("#joinEmail").val()
      password = $("#joinPassword").val()

      $("#joinGivenNameError").html("Please enter first name").css("visibility", "visible") unless firstName.length
      $("#joinFamilyNameError").html("Please enter last name").css("visibility", "visible") unless lastName.length
      if not email.length
        $("#joinEmailError").html("Please enter email").css("visibility", "visible")
      else if not App.Util.isEmailValid(email)
        $("#joinEmailError").html("Please enter valid email").css("visibility", "visible")
      $("#joinPasswordError").html("Please enter password").css("visibility", "visible") unless password.length

      return not hasAjaxError()

    processLogin: (data) ->
      $("#loginError").html("")
      if data is "OK"
        window.location = "/"
      else
        $("#loginError")[0].className = "textError"
        $("#loginError").html(data.message)

    App.Home = new Home