$ ->
  return unless $("#uid")[0] # if user is not logged in

  class Activities

    constructor: ->
      @uid = $("#uid").val()
      @activitiesIO = io.connect('/activities', window.copt)
      @activitiesIO.on 'init', (data) => @updateActivityCount(data)
      @activitiesIO.on 'new', => @addActivityCount()

    accept: (aid) ->
      $.post '/projects/confirm', {aid: aid, answer: true}, (data, status, xhr) =>
        if data
          $("#activity#{aid}").replaceWith(data)
          @subtractActivityCount()

    decline: (aid) ->
      $.post '/projects/confirm', {aid: aid, answer: false}, (data, status, xhr) =>
        if data
          $("#activity#{aid}").replaceWith(data)
          @subtractActivityCount()

    getActivityCount: -> parseInt($("#activityBadge").html())

    addActivityCount: ->
      newActivityCount = @getActivityCount() + 1
      @updateActivityCount(newActivityCount)

    subtractActivityCount: ->
      newActivityCount = @getActivityCount() - 1
      @updateActivityCount(newActivityCount)

    updateActivityCount: (newCount) ->
      badge = $("#activityBadge")
      badge.html(newCount)

      badge.show() if newCount

  App.activities = new Activities
