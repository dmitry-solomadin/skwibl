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
        console.log data
        $('#inviteModal').find("#projectParticipants").html(data)
        $('#inviteModal').modal('show')

    inviteById: ->
      $("#inviteError").html("")
      uid = $("#inviteIdInput").valc()
      pid = $("#inviteModal").find(".pid").val()
      $.post '/projects/invite', {uid: uid, pid: pid}, (data, status, xhr) ->
        if data
          $("#inviteError")[0].className = "textSuccess"
          $("#inviteError").html("Invitation has been sent.")
        else
          $("#inviteError")[0].className = "textError"
          $("#inviteError").html("Unsuccessful")

    removeUserFromProject: (uid) ->
      pid = $("#inviteModal").find(".pid").val()
      $.post '/projects/remove', {pid: pid, id: uid}, (data, status, xhr) ->
        $("#participant#{data.uid}").fadeOut() if data

  App.projects = new Projects
