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
exports.files = function(req, res) {
  res.render('partials/files');
};

/*
 * POST
 * Upload file
 */
exports.uploadFile = function(req, res, next) {
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
