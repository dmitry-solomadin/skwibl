
/**
 * Module dependencies.
 */

var crypto = require('crypto')
  , generatePassword = require('password-generator')
  , _ = require('underscore');

var cfg = require('../config');

exports.emailType = function(x) {
  return 'emails:' + x + ':type';
};

exports.emailUid = function(x) {
  return 'emails:' + x + ':uid';
};

exports.getValue = function(x) {
  return x.value;
};

exports.getType = function(x) {
  return x.type;
};

exports.hash = function(email) {
  var hash = crypto.createHash('md5');
  hash.update(new Date + email, 'ascii');
  return hash.digest('hex');
};

exports.genPass = function() {
  return generatePassword.call(null, cfg.PASSWORD_LENGTH, cfg.PASSWORD_EASYTOREMEMBER);
};

exports.purify = function(obj) {
  if(!obj) {
    return null;
  }
  for(var prop in obj) {
    if(!obj[prop]) {
      delete obj[prop];
    }
  }
  if(_.isEmpty(obj)) {
    return null;
  }
  return obj;
};

exports.getName = function(user) {
  if(user.name) {
    var name = user.name;
    if(name.givenName && name.familyName) {
      return name.givenName + ' ' + name.familyName;
    }
    if(name.givenName) {
      return name.givenName;
    }
    if(name.familyName) {
      return name.familyName;
    }
  }
  if(user.displayName) {
    return user.displayName;
  }
  return user.emails[0].value;
};
