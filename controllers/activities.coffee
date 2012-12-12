db = require '../db'

tools = require '../tools'

#
# GET
# Get all activities
#
exports.index = (req, res, next) ->
  return db.activities.index req.user.id, (err, activities) ->
    if not activities or activities.length is 0
      return res.render 'index', template:"activities/index", activities:activities

    unless err
      return db.activities.getDataActivities activities, (err) ->
        unless err
          return res.render 'index', template:"activities/index", activities:activities
        return next err
    return next err
