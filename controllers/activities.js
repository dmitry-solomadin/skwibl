var db = require('../db');

var tools = require('../tools');

/*
 * GET
 * Get all activities
 */
exports.index = function (req, res, next) {
  return db.activities.get(req.user.id, function (err, activities) {
    if (!err) {
      return res.render('index', {
        template:"activities/index",
        activities:activities
      });
    }
    return next(err);
  });
};
