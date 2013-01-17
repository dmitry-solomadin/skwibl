readOnlyActivities = ['projectJoin', 'projectLeave', 'newComment', 'newTodo', 'todoResolved', 'todoReopened', 'fileUpload']
changeLoggables = ['projectJoin', 'projectLeave', 'newComment', 'newTodo', 'todoResolved', 'todoReopened', 'fileUpload']

exports.isReadOnly = (activity) ->
  for readOnlyActivity in readOnlyActivities
    return true if activity.type is readOnlyActivity
  return false

exports.isChangeLoggable = (type) ->
  for changeLoggable in changeLoggables
    return true if type is changeLoggable
  return false