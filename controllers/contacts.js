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
exports.contacts = function(req, res, next) {
  db.getUserContacts(req.user.id, function(err, contacts) {
    if(!err) {
      return res.render('index', {contacts: contacts});
    }
    return next(err);
  });
};

/*
 * POST
 * Add local contact
 */
exports.addContact = function(req, res) {
  db.addUserContact(req.user.id, req.body.id, function(err, val) {
    if(!err) {
      return res.send(true);
    }
    return res.send(false);
  });
};

/*
 * POST
 * Delete contact
 */
exports.deleteContact = function(req, res, next) {
  db.deleteUserContacts(req.user.id, req.body.id, function(err, val) {
    if(!err) {
      return res.send(true);
    }
    return res.send(false);
  });
};

/*
 * POST
 * Invite contact with social network
 */
exports.inviteContact = function(req, res, next) {
  db.inviteUserContact(req.user.id, req.body.id, req.body.provider, function(err, val) {
    if(!err) {
      return res.send(true);
    }
    return res.send(false);
  });
};

/*
 * POST
 * Invite contact by email
 */
exports.inviteEmailContact = function(req, res, next) {
  db.inviteEmailUserContact(req.user.id, req.body.email, function(err) {
    if(!err) {
      return res.send(true);
    }
    return res.send(false);
  });
};

/*
 * POST
 * Invite contact by link
 */
exports.inviteLinkContact = function(req, res, next) {
  db.inviteLinkUserContact(req.user.id, function(err, link) {
    if(!err) {
      return res.send(link);
    }
    return res.send(false);
  });
};

/*
 * POST
 * Confirm user as a contact
 */
exports.confirmContact = function(req, res, next) {
  db.confirmUserContact(req.user.id, req.body.id, req.body.accept, function(err, val) {
    if(!err) {
      return res.send(true);
    }
    return res.send(false);
  });
};
