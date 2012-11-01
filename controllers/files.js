/******************************************
 *             FILE MANAGEMENT            *
 ******************************************/

/**
 * Module dependencies.
 */

var fs = require('fs')
  , path = require('path');

var db = require('../db')
  , tools = require('../tools')
  , cfg = require('../config');

/*
 * GET
 * User files
 */
exports.get = function(req, res) {
  res.render('partials/files');
};

/*
 * POST
 * Add file from cloud source
 */
exports.add = function(req, res) {
  //TODO
};

/*
 * POST
 * delete file
 */
exports.delete = function(req, res) {
  //TODO
};

/*
 * POST
 * Update file
 */
exports.update = function(req, res) {
  //TODO
};

/*
 * POST
 * Upload file
 */
exports.upload = function(req, res, next) {
  //TODO implement upload continue
  if(req.xhr){
    var pid = req.query.pid
      , dir = './uploads/' +  pid
      , size = req.header('x-file-size')
      , name = path.basename(req.header('x-file-name'))
      , type = tools.getFileType(path.extname(name));
    if(!type) {
      return next(new Error('Unsopported file type'));
    }

    var ws = fs.createWriteStream(dir + '/' + type + '/' + name, {
      mode: cfg.FILE_PERMISSION
    });

    req.on('data', function(chunk) {
      ws.write(chunk);
    });

    req.on('end', function() {
      return db.files.add(req.user.id, pid, name, function(err, file) {
        return res.json({
          success: true
        , id: file.id
        , name: name
        });
      });
    });

    req.on('close', function() {
      return res.json({
        success: false
      , name: name
      });
    });
  } else {
    return next(new Error('Can not upload file this way.'));
  }
};
