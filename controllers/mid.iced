#
# ALL
# Check authentication
#
exports.isAuth = (req, res, next) =>
  return next() if req.isAuthenticated()
  if req.method is 'GET'
    req.flash 'message', "This section requires login to view."
    return res.redirect '/sign_in'
  return res.json
    success: no
    message: 'not authenticated'

#
# ALL
# Check that user id in params matches authenticated user id.
#
exports.isCurrentUser = (req, res, next) =>
  return next() if req.user.id is req.params.id
  if req.method is 'GET'
    req.flash 'error', "You can't view this page."
    return res.redirect '/'
  return res.json
    success: no
    message: 'not authenticated'

#
# ALL
# Check if the user is the project member
#
exports.isMember = (req, res, next) =>
  pid = req.params.pid or req.body.pid or req.query.pid
  @db.mid.isMember req.user.id, pid, (err, val) =>
    return next() if val
    if req.method is 'GET'
      return res.redirect 'back'
    return res.json
      success: no
      message: 'not a member'

#
# All
# Check if the file belongs to the project
#
exports.isFileInProject = (req, res, next) =>
  pid = req.params.pid or req.body.pid
  fid = req.params.fid or req.body.fid
  @db.mid.isFileInProject fid, pid, (err, val) =>
    return next() if val
    if req.method is 'GET'
      return res.redirect 'back'
    return res.json
      success: no
      message: "file doesn't belong to the project"

#
# POST
# Check if the user is project owner
#
exports.isOwner = (req, res, next) =>
  @db.mid.isOwner req.user.id, req.body.pid, (err, val) =>
    return next() if val
    return res.json
      success: no
      message: 'has no permission'

#
# POST
# Check if the user is invited to a project
#
exports.isInvited = (req, res, next) =>
  @db.mid.isInvited req.user.id, req.body.aid, (err, val) =>
    return next() if val
    return res.json
      success: no
      message: 'not invited'
