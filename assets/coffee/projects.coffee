$ ->
  class Projects

    constructor: ->
      @uid = $("#uid").val()

      $("#showInviteParticipants").on "click", => @toogleParticipants()

    toogleParticipants: () -> $("#inviteParticipants").toggle("slow")

    deleteProject: (pid) ->
      if confirm("Are you sure?")
        $.post '/projects/delete', {pid: pid}, (data, status, xhr) ->
          $("#project#{pid}").fadeOut()

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
            $("#inviteError").html("Invitation has been sent.")
        else
          $("#inviteError").html("Unsuccessful.")

    removeUserFromProject: (uid) ->
      pid = $("#inviteModal").find(".pid").val()
      $.post '/projects/remove', {pid: pid, id: uid}, (data, status, xhr) ->
        $("#participant#{data.uid}").fadeOut() if data

  App.projects = new Projects
