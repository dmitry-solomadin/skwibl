/******************************************
 *             FILE MANAGEMENT            *
 ******************************************/

/**
 * Module dependencies.
 */

var fs = require('fs')
  , path = require('path');

var tools = require('../tools')
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
    var dir = './uploads/' +  req.query.pid
      , size = req.header('x-file-size')
      , name = path.basename(req.header('x-file-name'))
      , type = tools.getFileType(path.extname(fName));
    tools.createProjectDir(dir, function(err) {
      if(err) {
        return next(err);
      }
      return tools.createProjectFileDir(dir, type, function(err) {
        if(err) {
          return next(err);
        }
        var ws = fs.createWriteStream(dir + '/' + type + '/' + name, {
          mode: cfg.FILE_PERMISSION
        });

        req.on('data', function(chunk) {
          ws.write(chunk);
        });

        req.on('end', function() {
          return res.json({
            success: true
          , fileName: name
          });
        });

        req.on('close', function() {
          return res.json({
            success: false
          , fileName: name
          });
        });
      });
    });
  } else {
    return next(new Error('Can not upload file this way.'));
  }
};
