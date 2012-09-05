/******************************************
 *                 SEARCH                 *
 ******************************************/

/*
 * GET
 * Search
 */
exports.search = function(req, res) {
  res.render('index', {template: 'search'});
};
