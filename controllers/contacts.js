/******************************************
 *           CONTACTS MANAGEMENT          *
 ******************************************/

/**
 * Module dependencies.
 */

var db = require('../db');

/*
 * GET
 * Get contact list
 */
exports.get = function(req, res, next) {
  db.contacts.get(req.user.id, function(err, contacts) {
    if(!err) {
      return res.render('index', {contacts: contacts});
    }
    return next(err);
  });
};
