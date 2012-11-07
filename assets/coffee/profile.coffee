$ ->
  class UserProfile

    connect: (provider) -> window.location = "/connect/#{provider}"

    disconnect: (provider) ->
      $.post '/auth/disconnect', {provider: provider}, (data, status, xhr) ->
        return unless status is 'success'

        facebook = $("##{provider}")
        facebook.empty()
        facebook.html('disconnected')

  App.userProfile = new UserProfile


