/******************************************
 *           PROJECTS MANAGEMENT          *
 ******************************************/


/**
 * Module dependencies.
 */

var fs = require('fs')
  , _ = require('underscore');

var tools = require('../tools')
    cfg = require('../config');

exports.setUp = function(client, db) {

  var mod = {};

  mod.get = function(id, fn) {
    client.smembers('users:' + id + ':projects', function(err, array) {
      if(!err && array && array.length) {
        var projects = [];
        return tools.asyncParallel(array, function(left, pid) {
          return db.projects.getData(pid, function(err, project) {
            if(!err && project) {
              projects.push(project);
              return tools.asyncDone(left, function() {
                return tools.asyncOpt(fn, null, projects);
              });
            }
            return tools.asyncOpt(fn, err, []);
          });
        });
      }
      return tools.asyncOpt(fn, err, []);
    });
  };

  mod.getData = function(pid, fn) {
    client.hgetall('projects:' + pid, function(err, project) {
      if(!err && project) {
        return db.projects.getUsers(pid, function(err, array) {
          project.users = array;
          return tools.asyncOpt(fn, err, project);
        });
      }
      return tools.asyncOpt(fn, err, null);
    });
  };

  mod.getUsers = function(pid, fn) {
    client.smembers('projects:' + pid + ':users', function(err, array) {
      if(!err && array && array.length) {
        var users = [];
        return tools.asyncParallel(array, function(left, uid) {
          db.contacts.getInfo(uid, function(err, user) {
            users.push(user);
            return tools.asyncDone(left, function() {
              return tools.asyncOpt(fn, null, users);
            });
          });
        });
      }
      return tools.asyncOpt(fn, err, []);
    });
  };

  mod.add = function(uid, name, fn) {
    client.incr('projects:next', function(err, val) {
      if(!err) {
        var dir = './uploads/' + val;
        fs.mkdir(dir, cfg.DIRECTORY_PERMISSION, function(err) {
          fs.mkdir(dir + '/video', cfg.DIRECTORY_PERMISSION);
          fs.mkdir(dir + '/image', cfg.DIRECTORY_PERMISSION);
        });
        var project = {};
        project.id = val;
        project.name = name;
        project.owner = uid;
        project.start = new Date;
        project.status = 'new';
        client.hmset('projects:' + val, project);
        client.sadd('projects:' + val + ':users', uid);
        client.sadd('users:' + uid + ':projects', val);
        return tools.asyncOpt(fn, null, project);
      }
      return tools.asyncOpt(fn, err, null);
    });
  };

  mod.deleteUsers = function(pid, fn) {
    client.smembers('projects:' + pid + ':users', function(err, array) {
      if(!err && array && array.length) {
        db.contacts.deleteContacts(pid, array, 0, fn);
      }
      client.del('projects:' + pid + ':users');
      return tools.asyncOpt(fn, err, pid);
    });
  };

  mod.deleteActions = function(pid, type, fn) {
    client.lrange('projects:' + pid + ':' + type, function(err, array) {
      if(!err && array && array.length) {
        return tools.asyncParallel(array, function(left, aid) {
          client.del('actions:' + aid, pid);
          return tools.asyncDone(left, function() {
            return tools.asyncOpt(fn, null, pid);
          });
        });
      }
      client.del('projects:' + pid + ':' + type);
      return tools.asyncOpt(fn, err, pid);
    });
  };

  mod.delete = function(pid, fn) {
    db.projects.deleteUsers(pid);
    db.projects.deleteActions(pid, 'chat');
    client.del('projects:' + pid, fn);
  };

  mod.setProperties = function(pid, properties, fn) {
    var purifiedProp = tools.purify(properties);
    return client.hmset('projects:' + pid, purifiedProp, fn);
  };

  mod.invite = function(pid, id, user, fn) {
    if(user.id === id) {
      return tools.asyncOptError(fn, 'Cannot invite yourself');
    }
    //Check if user exists
    return client.exists('users:' + user.id, function(err, val) {
      if(!err && val) {
        client.sadd('projects:' + pid + ':unconfirmed', user.id);
        //TODO Send invitation to user. || sockets
        db.activities.add(pid, user.id, 'projectInvite', id);
        return tools.asyncOpt(fn, null, user);
      }

      if (!val) {
        return tools.asyncOpt(fn, new Error('Record not found'));
      }

      return tools.asyncOpt(fn, err);
    });
  };

  mod.inviteSocial = function(pid, provider, providerId, fn) {
    //TODO
  };

  mod.inviteEmail = function(pid, id, email, fn) {
    db.users.findByEmail(email, function(err, user){
      if (err) {
        return tools.asyncOpt(fn, err);
      }

      if (!user){
        return tools.asyncOptError(fn, "User with this email is not found");
      }

      return mod.invite(pid, id, user, fn);
    })
  };

  mod.inviteLink = function(pid, fn) {
    //TODO
  };

  mod.accept = function(pid, id, fn) {
    //Get project members
    client.smembers('projects:' + pid + ':users', function(err, array) {
      if(!err && array) {
        return tools.asyncParallel(array, function(left, cid) {
          //Add the user as a contact to all project members
          client.sadd('users:' + cid + ':contacts', id);
          //And vise-versa
          client.sadd('users:' + id + ':contacts', cid);
          return tools.asyncDone(left, function() {
            //Add the user to the project
            client.smove('projects:' + pid + ':unconfirmed', 'projects:' + pid + ':users', id);
            //Add the project to the user
            client.sadd('users:' + id + ':projects', pid);
            return fn(null);
          });
        });
      }
      fn(err);
    });
  };

  mod.decline = function(pid, id, fn) {
    client.srem('projects:' + pid + ':unconfirmed', id, fn);
  };

  mod.remove = function(pid, id, fn) {
    //Remove project from user projects
    client.srem('users:' + id + ':projects', pid);
    //Get project members
    client.smembers('projects:' + pid + ':users', function(err, array) {
      if(!err && array && array.length) {
        db.contacts.recalculate(id, array, pid);
        return tools.asyncParallel(array, function(left, cid) {
          //Recalculate member contacts
          db.contacts.recalculate(cid, [id], pid);
          return tools.asyncDone(left, function() {
            //Remove user from project members
            client.srem('projects:' + pid + ':users', id);
            return tools.asyncOpt(fn, null);
          });
        });
      }
      return tools.asyncOpt(fn, err);
    });
  };

  mod.confirm = function(aid, uid, answer, fn) {
    return client.hget('activities:' + aid, 'project', function(err, val) {
      if(!err && val) {
        if(answer === 'true') {
          client.hset('activities:' + aid, 'status', 'accepted');
          return db.projects.accept(val, uid, fn);
        }
        client.hset('activities:' + aid, 'status', 'declined');
        return db.projects.decline(val, uid, fn);
      }
      return tools.asyncOpt(fn, err, val);
    });
  };

  mod.set = function(id, pid, fn) {
    client.set('users:' + id + ':current', pid, fn);
  };

  mod.current = function(id, fn) {
    client.get('users:' + id + ':current', fn);
  };

  return mod;

};
