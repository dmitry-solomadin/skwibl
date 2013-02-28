$ ->
  class Home

    constructor: ->
      Placeholders.init()

      $(".tooltipize").tooltip()

      $("#forgotpasswordlink").click => @showForgotPassword()
      $("#backToLogin").click => @hideForgotPassword()
      $("#submitForgotPassword").click => @submitForgotPassword($("#forgotpassword_form"))

      $("#forgotpasswordlink_standalone").click => @showForgotPasswordStandalone()
      $("#backToLogin_standalone").click => @hideForgotPasswordStandalone()
      $("#submitForgotPassword_standalone").click => @submitForgotPassword($("#forgotpassword_form_standalone"))

      for loginForm in $(".loginForm")
        $(loginForm).data("process-submit", ((loginForm) => (data) => @processLogin(data, loginForm))(loginForm))

      $(".banner_nav a").on "click", ->
        $(".banner_nav a").removeClass("selected")
        $(@).addClass("selected")
        false

    showForgotPasswordStandalone: ->
      $(".forgotpass_wrapper").show().animate(left: 0)
      $(".signin_wrapper").animate(left: -$(window).width())

    hideForgotPasswordStandalone: ->
      $(".forgotpass_wrapper").animate(left: $(window).width())
      $(".signin_wrapper").animate(left: 0)

    showForgotPassword: ->
      $(".loginBlockWrapper > form:first").animate(left: -335)
      $(".loginBlockWrapper > form:last").animate(left: -335)

    hideForgotPassword: ->
      $(".loginBlockWrapper > form:first").animate(left: 0)
      $(".loginBlockWrapper > form:last").animate(left: 0)

    submitForgotPassword: (form) ->
      email = $(form).find("#forgotPasswordEmail").val()
      $(form).find("#forgotPasswordError")[0].className = ""
      $(form).find("#forgotPasswordError").html("Sending...")
      $.post '/forgotpassword', {email: email}, (data, status, xhr) ->
        if data
          $(form).find("#forgotPasswordError")[0].className = "textSuccess"
          $(form).find("#forgotPasswordError").html("New password has been sent to this email.")
        else
          $(form).find("#forgotPasswordError")[0].className = "textError"
          $(form).find("#forgotPasswordError").html("We don't have this email.")

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

    processLogin: (data, loginForm) ->
      errors = $(loginForm).find("#loginError")
      errors.html("")
      errors.removeClass("textError")
      if data is "OK"
        window.location = "/"
      else
        errors.addClass("textError")
        errors.html(data.message)

    App.Home = new Home
