$ ->
  class Projects

    constructor: ->
      @uid = $("#uid").val()

      $("#showInviteParticipants").on "click", => @toogleParticipants()

    toogleParticipants: () -> $("#inviteParticipants").toggle("slow")

    switchProject: ->
      $.post '/dev/projects/get', {
      pid: @getSelectedProjectId()
      }, (data, status, xhr) ->
        info = $('#info')
        users = $('#projectUsers')
        info.empty()
        users.empty()
        if status == 'success' and data
          for el in data
            if el == 'users'
              for user in data.users
                if user.id != @uid
                  users.append("<input type='radio' name='user' value='#{user.id}' onchange='App.projects.switchUser()'/>#{user.displayName}<br>")
            else
              info.append("<li>#{el} : #{data[el]}</li>")

    deleteProject: ->
      $.post '/projects/delete', {
      pid: @getSelectedProjectId()
      }, (data, status, xhr) ->
        if status == 'success'
          $("[name=project]:checked").remove()

    deleteUser: ->
      $.post '/projects/remove',
        {pid: @getSelectedProjectId(), id: @getSelectedUserId}

    inviteUser: ->
      uid = $("#userIdInput").valc()
      $.post '/projects/invite', {
      uid: uid,
      pid: @getSelectedProjectId()
      }, (data, status, xhr) ->
        if status == 'success'
          console.log('invited')

    accept: ->
      console.log('accept invitation')
      $.post '/projects/confirm', {
      aid: @getSelectedActivityId(), answer: true
      }, (data, status, xhr) ->
        if status == 'success'
          console.log('accepted')

    decline: ->
      console.log('decline invitation')
      $.post '/projects/confirm', {
      aid: @getSelectedActivityId(), answer: true
      }, (data, status, xhr) ->
        if status == 'success'
          console.log('declined')


    getSelectedUserId: -> $("[name=user]:checked").val()

    getSelectedActivityId: -> $("[name=activity]:checked").val()

    getSelectedProjectId: -> $("[name=project]:checked").val()


  App.projects = new Projects
