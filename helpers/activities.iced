readOnlyActivities = ['projectJoin', 'projectLeave', 'newComment', 'newTodo', 'todoResolved', 'todoReopened', 'fileUpload']
changeLoggables = ['projectJoin', 'projectLeave', 'newComment', 'newTodo', 'todoResolved', 'todoReopened', 'fileUpload']

exports.isReadOnly = (activity) ->
  activity.type in readOnlyActivities

exports.isChangeLoggable = (type) ->
  type in changeLoggables
