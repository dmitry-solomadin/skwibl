/******************************************
 *             FILE MANAGEMENT            *
 ******************************************/


/**
 * Module dependencies.
 */

var ctrls = require('../controllers');

exports.configure = function(app, passport) {

 /*
  * all user photos
  */
  app.get('/photos', ctrls.isAuth, ctrls.photos);

 /*
  * all user videos
  */
  app.get('/videos', ctrls.isAuth, ctrls.videos);

 /*
  * all user documents
  */
  app.get('/documents', ctrls.isAuth, ctrls.documents);

 /*
  * all user files
  */
  app.get('/files', ctrls.isAuth, ctrls.files);

 /*
  * upload new file
  */
  app.post('/files/add', ctrls.isAuth, ctrls.addFile);

 /*
  * delete file
  */
  app.post('/files/delete', ctrls.isAuth, ctrls.deleteFile);

 /*
  * update file
  */
  app.post('/files/update', ctrls.isAuth, ctrls.updateFile);

  /*
   * file upload
   */
  app.post('/file/upload', ctrls.isAuth, ctrls.uploadFile);

}
