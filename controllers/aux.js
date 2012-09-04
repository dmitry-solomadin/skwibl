/******************************************
 *           AUXILIARY FUNCTIONS          *
 ******************************************/

/*
 * GET
 * Dummy function for passport social strategies
 */
exports.empty = function(req, res){};

/*
 * All
 * 404 page
 */
exports.notFound = function(req, res) {
  if(req.method === 'GET') {
    return res.render('404', { title: 404 });
  }
  return res.json({
    success: false
  , message: 'route not found'
  });
};

/*
 * ALL
 * error page
 */
exports.error = function(err, req, res, next){
  if(req.method === 'GET') {
    res.render('404', { title: 'Error' });
  }
  return res.json({
    success: false
  , message: err
  });
}; 
