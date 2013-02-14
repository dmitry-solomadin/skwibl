exports.error = ->
  return @req.flash 'error'

exports.message = ->
  return @req.flash 'message'

exports.warning = ->
  return @req.flash 'warning'

exports.errorMessages = ->
  return @req.flash 'objectErrors'
