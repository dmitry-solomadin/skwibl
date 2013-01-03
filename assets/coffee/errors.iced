$ ->
  class Errors

    constructor: -> @initErrors()

    initErrors: ->
      errors = $("#errorMessages li")
      for error in errors
        errorId = $(error).data("error-id")
        $("##{errorId}").addClass("error")


  App.errors = new Errors
