var db = require('../db');

exports.currentUser = function (id) {
  if (id) {
    return id == this.req.user.id;
  }

  return this.req.user;
};

exports.flashError = function () {
  return this.req.flash('error');
};

exports.flashMessage = function () {
  return this.req.flash('message');
};

exports.flashWarning = function () {
  return this.req.flash('warning');
};

exports.errorMessages = function () {
  return this.req.flash('objectErrors');
};

