/******************************************
 *                 SEARCH                 *
 ******************************************/

/*
 * GET
 * Search
 */
exports.search = function(req, res) {
  res.render('index', { title: req.params.id, template: 'search'});
};
