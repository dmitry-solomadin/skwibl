var db = require('../db');

var tools = require('../tools');

/*
 * GET
 * Get all activities
 */
exports.index = function (req, res, next) {
  return db.activities.get(req.user.id, function (err, activities) {
    if (!activities || activities.length == 0) {
      return res.render('index', {
        template:"activities/index",
        activities:activities
      });
    }

    if (!err) {
      return db.activities.getDataActivities(activities, function (err) {
        if (!err) {
          return res.render('index', {
            template:"activities/index",
            activities:activities
          });
        }

        return next(err);
      })
    }
    return next(err);
  });
};
