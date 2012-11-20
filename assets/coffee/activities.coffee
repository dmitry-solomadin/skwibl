$ ->
  class Activities

    constructor: ->
      @uid = $("#uid").val()

    accept: (aid) ->
      $.post '/projects/confirm', {aid: aid, answer: true}, (data, status, xhr) ->
        $("#activity#{aid}").replaceWith(data) if data

    decline: (aid) ->
      $.post '/projects/confirm', {aid: aid, answer: false}, (data, status, xhr) ->
        $("#activity#{aid}").replaceWith(data) if data

  App.activities = new Activities

