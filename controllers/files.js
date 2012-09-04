/******************************************
 *             FILE MANAGEMENT            *
 ******************************************/

/**
 * Module dependencies.
 */

var fs = require('fs')
  , path = require('path');

var cfg = require('../config');

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
  if(req.xhr){
    var dirName = './static/private/' +  req.user.id
      , dir = fs.mkdir(dirName, cfg.DIRECTORY_PERMISION);
    var fSize = req.header('x-file-size')
      , fType = req.header('x-file-type')
      , basename = path.basename
      , fName = basename(req.header('x-file-name'));
    var ws = fs.createWriteStream(dirName + '/' + fName);

    // TODO parse mime type

    req.on('data', function(chunk) { 
      ws.write(chunk);
    });

    req.on('end', function() {
      return res.json({
        success: true
      , fileName: fName
      });
    });

    req.on('close', function() {
      return res.json({
        success: false
      , fileName: fName
      });
    });
  }
};
