readOnlyActivities = ['projectJoin', 'projectLeave', 'newComment', 'newTodo', 'todoResolved', 'todoReopened', 'fileUpload']

exports.isReadOnly = (activity) ->
  for readOnlyActivity in readOnlyActivities
    return true if activity.type is readOnlyActivity
  return false