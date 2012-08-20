/******************************************
 *           FRIENDS MANAGEMENT           *
 ******************************************/

/**
 * Module dependencies.
 */

var db = require('../db');

/*
 * GET
 * Get friend list
 */
exports.friends = function(req, res, next) {
  db.getUserFriends(req.user.id, function(err, friends) {
    if(!err) {
      return res.render('index', {friends: friends});
    }
    return next(err);
  });
  //   res.render('index', {template: 'addfriend', menu: 3 });
  //   res.render('index', {'users' : users, title: req.params.id, title: req.params.id, template: 'friends', menu: 3 });
};

/*
 * POST
 * Add local friend
 */
exports.addFriend = function(req, res) {
  db.addUserFriend(req.user.id, req.body.id, function(err, val) {
    if(!err) {
      return res.send(true);
    }
    return res.send(false);
  });
};

/*
 * POST
 * Delete friend
 */
exports.deleteFriend = function(req, res, next) {
  db.deleteUserFriend(req.user.id, req.body.id, function(err, val) {
    if(!err) {
      return res.send(true);
    }
    return res.send(false);
  });
};

/*
 * POST
 * Invite friend with social network
 */
exports.inviteFriend = function(req, res, next) {
  db.inviteUserFriend(req.user.id, req.body.id, req.body.provider, function(err, val) {
    if(!err) {
      return res.send(true);
    }
    return res.send(false);
  });
};

/*
 * POST
 * Invite friend by email
 */
exports.inviteEmailFriend = function(req, res, next) {
  db.inviteEmailUserFriend(req.user.id, req.body.email, function(err) {
    if(!err) {
      return res.send(true);
    }
    return res.send(false);
  });
};

/*
 * POST
 * Invite friend by link
 */
exports.inviteLinkFriend = function(req, res, next) {
  db.inviteLinkUserFriend(req.user.id, function(err, link) {
    if(!err) {
      return res.send(link);
    }
    return res.send(false);
  });
};

/*
 * POST
 * Confirm user as a friend
 */
exports.confirmFriend = function(req, res, next) {
  db.confirmUserFriend(req.user.id, req.params.id, req.params.accept, function(err, val) {
    if(!err) {
      return res.send(true);
    }
    return res.send(false);
  });
};
