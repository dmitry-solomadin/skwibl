
/**
 * Module dependencies.
 */

var cluster = require('cluster')
  , os = require('os')
  , fs = require('fs')
  , crypto = require('crypto')
  , generatePassword = require('password-generator')
  , _ = require('underscore');

var cfg = require('../config');

var numCPUs = os.cpus().length;

exports.getUsers = function(clients) {
  var ids = [];
  clients.forEach(function(client) {
    var ssid = client.id
      , hsn = client.manager.handshaken
      , id = hsn[ssid].user.id;
    ids.push(id);
  });
  return ids;
};

exports.emailType = function(x) {
  return 'emails:' + x + ':type';
};

exports.emailUid = function(x) {
  return 'emails:' + x + ':uid';
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

exports.returnStatus = function(err, res) {
  if(!err) {
    return res.send(true);
  }
  res.send(false);
};

exports.getFileType = function(ext) {
  var extension = ext.toLowerCase();
  if(cfg.VIDEOS_EXT.indexOf(extension) !== -1) {
    return 'videos';
  } else if(cfg.IMAGES_EXT.indexOf(extension) !== -1) {
    return 'images';
  }
  return null;
};

exports.include = function(dir, fn) {
  fs.readdirSync(dir).forEach(function(name){
    var len = name.length
      , ext = name.substring(len - 3, len)
      , isModule = name !== 'index.js' && ext === '.js';
    if(isModule) {
      var mod = require(dir + '/' + name)
        , shortName = name.substring(0, len - 3);
      fn(mod, shortName);
    }
  });
};

exports.async = function(fn) {
  return process.nextTick(function() {
    fn(err, val);
  });
};

exports.asyncOpt = function(fn, err, val) {
  if(fn) {
    return process.nextTick(function() {
      fn(err, val);
    });
  }
};

exports.asyncOrdered = function(array, index, fn, done) {
  index = index || 0;
  if(index === array.length) {
    return done();
  }
  fn();
  process.nextTick(function() {
    tools.asyncOrdered(array, index++, fn, done);
  });
};

exports.asyncParallel = function(array, fn) {
  var left = array.length - 1;
  for(var i = 0, len = array.length; i < len; i++) {
    (function(val) {
      process.nextTick(function() {
        fn(left, val);
        --left;
      });
    })(array[i]);
  }
};

exports.asyncDone = function(left, fn) {
  if(left === 0) {
    return process.nextTick(fn);
  }
};

exports.exitNotify = function(worker, code, signal) {
  console.log('Worker ' + worker.id + ' died: ' + worker.process.pid);
};

exports.startCluster = function(stop, start) {
  var t;
  if(cluster.isMaster) {
    for(var i = 0; i < numCPUs; i++) {
      cluster.fork();
    }
    cluster.on('exit', function(worker, code, signal) {
      clearInterval(t);
      stop(worker, code, signal);
    });
  } else {
    t = setInterval(function() {
      gc();
    }, cfg.GC_INTERVAL);
    start(cluster);
  }
};
