/******************************************
 *             FILE MANAGEMENT            *
 ******************************************/


/**
 * Module dependencies.
 */

var ctrls = require('../controllers');

exports.configure = function(app, passport) {

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
