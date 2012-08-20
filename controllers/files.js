/******************************************
 *             FILE MANAGEMENT            *
 ******************************************/

/*
 * GET
 * User files
 */
exports.files = function(req, res) {
  res.render('index', { template: 'files' });
};

/*
 * GET
 * User videos
 */
exports.videos = function(req, res) {
  res.render('index', { template: 'videos' });
};

/*
 * GET
 * User photos
 */
exports.photos = function(req, res) {
  res.render('index', { template: 'photos' });
};

/*
 * GET
 * User documents
 */
exports.documents = function(req, res) {
  res.render('index', { template: 'documents' });
};
