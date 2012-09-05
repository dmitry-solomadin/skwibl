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
  app.get('/files', ctrls.mid.isAuth, ctrls.files.get);

 /*
  * add file from cloud source
  */
  app.post('/files/add', ctrls.mid.isAuth, ctrls.files.add);

 /*
  * delete file
  */
  app.post('/files/delete', ctrls.mid.isAuth, ctrls.files.delete);

 /*
  * update file
  */
  app.post('/files/update', ctrls.mid.isAuth, ctrls.files.update);

  /*
   * file upload
   */
  app.post('/file/upload', ctrls.mid.isAuth, ctrls.files.upload);

}
