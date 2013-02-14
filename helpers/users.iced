exports.currentUser = (id) ->
  return id is @user.id if id
  return @user
