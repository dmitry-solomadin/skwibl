$ ->
  class UserProfile

    connect: (provider) -> window.location = "/connect/#{provider}"

    disconnect: (provider) ->
      $.post '/auth/disconnect', {provider: provider}, (data, status, xhr) ->
        return unless status is 'success'

        facebook = $("##{provider}")
        facebook.empty()
        facebook.html('disconnected')

    files: (provider) ->
      $.get "/files/#{provider}?path=Skwibl_Wireframes_3_1%2F", (data, status, xhr) ->
        console.log status

  App.userProfile = new UserProfile


