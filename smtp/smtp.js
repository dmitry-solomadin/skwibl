
/**
 * Module dependencies.
 */

var email = require('emailjs');

var cfg = require('../config')
  , tools = require('../tools/tools');

var smtp  = email.server.connect({
  user: cfg.SMTP_USER
, password: cfg.SMTP_PASSWORD
, host: cfg.SMTP_HOST
, ssl: cfg.SMTP_SSL
});

exports.sendRegMail = function(user, fn) {
  var email = user.emails[0].value
    , msg = '<html>You are successfuly registred at <a href="' + cfg.DOMAIN + '">' + cfg.DOMAIN +'</a> with ' +
  user.provider +'.<br><br>Registration info<br>login: ' +
  email +'<br>password: ' +
  user.password + '</html>';
  return smtp.send({
    text: "enable html to see registration details",
    from: cfg.DOMAIN + " <" + cfg.SMTP_NOREPLY + ">",
    to: "<" + email + ">",
    subject: "Registration complete",
    attachment: [{
      data: msg,
      alternative:true
    }]
  }, function(err, message) {
    return process.nextTick(function () {
      fn(err, user);
    });
  });
};

exports.regNotify = function(req, res, next, user, link) {
  var email = user.emails[0].value
    , msg = '<html>You are about to register at <a href="' + cfg.DOMAIN + '">' + cfg.DOMAIN + '</a><br>Follow the link below to continue<br><a href="' +
  cfg.DOMAIN + '/confirm/' + link + '">' +
  cfg.DOMAIN + '/confirm/' + link + '</a><br> or just ignore this mail to cancel registration.<br><br>Registration info<br>login: ' +
  email +'<br>password: ' +
  user.password + '</html>';
  return smtp.send({
    text: "enable html to continue registration",
    from: cfg.DOMAIN + " <" + cfg.SMTP_NOREPLY + ">",
    to: "<" + email + ">",
    subject: "Confirm registration",
    attachment: [{
      data: msg,
      alternative:true
    }]
  }, function(err, message) {
    return process.nextTick(function () {
      if(err) {
        req.flash('error', 'Can not send confirmation to  ' + email);
        return res.redirect('/');
      } else {
        req.flash('message', 'User with email: ' + email + ' successfuly registred.');
        return res.redirect('/checkmail');
      }
    });
  });
};

exports.regPropose = function(user, friend, link, fn) {
  var email = friend.emails[0].value
    , name = tools.getName(user)
    , msg = '<html>' + name + ' invites you to <a href="' + cfg.DOMAIN + '">' + cfg.DOMAIN + '</a><br>Follow the link below to continue<br><a href="' +
  cfg.DOMAIN + '/confirm/' + link + '">' +
  cfg.DOMAIN + '/confirm/' + link + '</a><br><br>Registration info<br>login: ' +
  email +'<br>password: ' +
  friend.password + '</html>';
  return smtp.send({
    text: "enable html to accept invitation",
    from: cfg.DOMAIN + " <" + cfg.SMTP_NOREPLY + ">",
    to: "<" + email + ">",
    subject: "Confirm registration",
    attachment: [{
      data: msg,
      alternative:true
    }]
  }, function(err, message) {
    if(err) {
      return process.nextTick(function () {
        fn(new Error('Can not send confirmation to  ' + email));
      });
    }
    return process.nextTick(function () {
      fn(err);
    });
  });
};

exports.passwordSend = function(req, res, next, user) {
  var email = user.emails[0].value
    , msg = '<html>Your registration info for <a href="' + cfg.DOMAIN + '">' + cfg.DOMAIN + '</a> is<br>login: ' +
  email +'<br>password: ' +
  user.password + '</html>';
  return smtp.send({
    text: "enable html to see registration details",
    from: cfg.DOMAIN + " <" + cfg.SMTP_NOREPLY + ">",
    to: "<" + email + ">",
    subject: "Confirm registration",
    attachment: [{
      data: msg,
      alternative:true
    }]
  }, function(err, message) {
    return process.nextTick(function () {
      if(err) {
        req.flash('error', 'Can not send confirmation to ' + email);
        return res.redirect('/forgotpassword');
      } else {
        req.flash('message', 'Password successfuly sent to email: ' + email);
        return res.redirect('/checkmail');
      }
    });
  });
};