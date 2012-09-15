/******************************************
 *            LOGIN & REGISTER            *
 ******************************************/


/**
 * Module dependencies.
 */

var _ = require('underscore');

var smtp = require('../smtp')
  , tools = require('../tools');

exports.setUp = function(client, db) {

  var mod = {};

  mod.findOrCreate = function(profile, fn) {
    var emails = profile.emails;
    return db.users.findByEmails(emails, function (err, user) {
      if(!user) {
        var email = emails[0].value
          , password = tools.genPass();
        return db.users.add({
          displayName: profile.displayName
        , providerId: profile.id
        , password: password
        , picture: profile._json.picture
        , status: 'registred'
        , provider: profile.provider
        }, profile.name, emails, function(err, user){
          if(user) {
            return smtp.sendRegMail(user, fn);
          }
          return tools.asyncOpt(fn, err, user);
        });
      }
      if(!user.picture) {
        user.picture = profile._json.picture;
        db.users.setProperties(user.id, {
          picture: user.picture
        });
      }
      var purifiedName = tools.purify(profile.name);
      if(!_.isEqual(user.name, purifiedName)) {
        user.name = _.extend(purifiedName, user.name);
        db.users.setName(user.id, user.name);
      }
      var diff = _.difference(profile.emails, user.emails)
      if(diff.length) {
        user.emails.concat(diff);
        db.users.addEmails(user.id, user.emails);
      }
      if(user.status === 'unconfirmed') {
        return db.users.persist(user, fn);
      }
      if(user.status === 'deleted') {
        return db.users.restore(user, fn);
      }
      return tools.asyncOpt(fn, err, user);
    });
  };

  return mod;

};
