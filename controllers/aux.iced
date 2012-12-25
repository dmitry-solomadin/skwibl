
#
# GET
# Dummy function for passport social strategies
#
exports.empty = (req, res)->

#
# All
#404 page
#
exports.notFound = (req, res) ->
  if req.method is 'GET'
    return res.render '404', title: 404
  return res.json
    success: false
    message: 'route not found'

#
# ALL
# error page
#
exports.error = (err, req, res, next) ->
  if req.method is 'GET'
    res.render '404', title: 'Error'
  return res.json
    success: false
    message: err
