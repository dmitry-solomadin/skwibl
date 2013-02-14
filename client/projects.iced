$ ->
  class Projects

    constructor: ->
      @uid = $("#uid").val()

      $("#inviteParticipantsToggle").on "click", => @toogleParticipants()

    toogleParticipants: ->
      if $("#inviteParticipants:visible")[0]
        $("#inviteParticipants").slideUp()
      else
        $("#inviteParticipants").slideDown()

      $("#inviteParticipantsToggle .caret-image").toggleClass("caret-image-top")

    deleteProject: (pid) ->
      if confirm("Are you sure?")
        $.post '/projects/delete', {pid: pid}, (data, status, xhr) =>
          @deleteProjectHtml pid

    deleteProjectHtml: (pid) ->
      $("#project#{pid}").toggle("normal")
      newProjectsCount = parseInt($.trim($("#projectCount").html())) - 1
      if newProjectsCount is 0
        $("#noProjectsText").show()
        $("#projectCountSemicolon").hide()
      else
        $("#projectCount").html(newProjectsCount)

    leaveProject: (pid) ->
      if confirm("Are you sure?")
        $.post '/projects/leave', {pid: pid}, (data, status, xhr) =>
          @deleteProjectHtml pid if data

    showInviteModal: (pid) ->
      $.get "/projects/#{pid}/participants", (data) ->
        $('#inviteModal').find(".pid").val(pid)
        $('#inviteModal').find("#projectParticipants").html(data)
        $('#inviteModal').modal('show')

    invite: ->
      $("#inviteError").html("")
      email = $("#inviteEmailInput").valc()
      pid = $("#inviteModal").find(".pid").val()
      $.post '/projects/invite', {email: email, pid: pid}, (data, status, xhr) ->
        if not data or data.error then $("#inviteError")[0].className = "textError" else $("#inviteError")[0].className = "textSuccess"

        if data
          if data.error
            $("#inviteError").html(data.msg)
          else
            $("#inviteModal").find("#projectParticipants").html(data.html) if data.html
            $("#inviteError").html(data.msg)
        else
          $("#inviteError").html("Unsuccessful.")

    removeUserFromProject: (uid) ->
      pid = $("#inviteModal").find(".pid").val()
      $.post '/projects/remove', {pid: pid, uid: uid}, (data, status, xhr) ->
        $("#participant#{data.uid}").fadeOut() if data

        if currentPage "projects/room/show"
          App.chat.chatIO.emit "userRemoved", uid
          App.chat.removeUser uid

  App.projects = new Projects
