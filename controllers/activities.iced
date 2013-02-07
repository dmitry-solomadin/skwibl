helpers = require '../helpers'

#
# GET
# Get all activities
#
exports.index = (req, res, next) =>
  return @db.activities.index req.user.id, (err, activities) =>
    if not activities or activities.length is 0
      return res.render 'index', template: "activities/index", activities: activities

    unless err
      return @db.activities.getDataActivities activities, (err) =>
        unless err
          # 'read' activities
          return @tools.asyncParallel activities, (activity) =>
            if activity.status is 'new' and helpers.activities.isReadOnly activity
              @db.activities.setStatus activity.id, "read"
            return @tools.asyncDone activities, =>
              return res.render 'index', template: "activities/index", activities: activities
        return next err
    return next err
