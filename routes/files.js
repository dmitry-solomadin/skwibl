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
   * project files
   */
  app.get('/files/:pid', ctrls.mid.isAuth, ctrls.files.project);

  /*
   * the file from the project
   */
  app.get('/files/:pid/:fid', ctrls.mid.isAuth, ctrls.mid.isMember, ctrls.mid.isFileInProject, ctrls.files.file);

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
   * file upload //TODO change to work with mid.isMember (be ready to listen req.data event understand how to use req.pause() properly)
   */
  app.post('/file/upload', ctrls.mid.isAuth, /*ctrls.mid.isMember,*/ ctrls.files.upload);

}
