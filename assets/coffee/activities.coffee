$ ->
  class Activities

    constructor: ->
      @uid = $("#uid").val()

    accept: (aid) ->
      console.log('accept invitation')
      $.post '/projects/confirm', {
      aid: aid, answer: true
      }, (data, status, xhr) ->
        if status == 'success'
          console.log('accepted')

    decline: (aid) ->
      console.log('decline invitation')
      $.post '/projects/confirm', {
      aid: aid, answer: false
      }, (data, status, xhr) ->
        if status == 'success'
          console.log('declined')

  App.activities = new Activities

