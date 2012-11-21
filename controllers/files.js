/******************************************
 *             FILE MANAGEMENT            *
 ******************************************/

/**
 * Module dependencies.
 */

var fs = require('fs')
  , path = require('path')
  , formidable = require('formidable');

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
 * GET
 * Project files
 */
exports.project = function(req, res) {
  //TODO
};

/*
 * GET
 * The file from the project
 */
exports.file = function(req, res) {
  var fid = req.params.fid;
  db.files.file(fid, function(err, file) {
    if(err) {
      return res.send(err);
    }
    var type = tools.getFileType(file.mime);
    res.writeHead(200, {
      'Content-Type': file.mime
    });

    var rs = fs.createReadStream('./uploads/' + file.project + '/' + type + '/' + file.name);
    rs.pipe(res);
  });
}

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
      , mime = tools.getFileMime(path.extname(name))
      , type = tools.getFileType(mime);
    if(!mime) {
      return res.json({
        success: false
      , name: name
      , error: 'Unsupported file type'
      });
    }

    var ws = fs.createWriteStream(dir + '/' + type + '/' + name, {
      mode: cfg.FILE_PERMISSION
    , flags: 'w'
    });

    console.log('upload');

    ws.on('error', function(err) {
      console.log(err);
    });

    ws.on('drain', function() {
      console.log('drain');
      req.resume();
    });

    ws.on('close', function() {
      console.log('close');
    });

    req.on('data', function(chunk) {
      console.log('chunk');
      ws.write(chunk);
    });

    req.on('end', function() {
      ws.destroySoon();
      console.log('end');
      return db.files.add(req.user.id, pid, name, mime, function(err, data) {
        console.log('here');
        return res.json({
          success: true
        , canvasId: data.canvasId
        , element: data.element
        });
      });
    });

    req.on('close', function() {
      ws.destroy();
      return res.json({
        success: false
      , name: name
      });
    });

//     req.resume();

  } else {
    var form = new formidable.IncomingForm();
    form.uploadDir = dir + '/' + type + '/';
    form.keepExtensions = true;
    form.parse(req, function(err, fields, files) {
      return db.files.add(req.user.id, pid, name, mime, function(err, file) {
        return res.json({
          success: true
        , id: file.id
        , name: name
        });
      });
    });
  }
};
