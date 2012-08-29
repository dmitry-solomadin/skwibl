/******************************************
 *           PROJECTS MANAGEMENT          *
 ******************************************/

/*
 * GET
 * Get all projects
 */
exports.projects = function(req, res) {
  res.render('index', { title: req.params.id, template: 'projects' , menu: 3});
};

/*
 * GET
 * Enter the project
 */
exports.project = function(req, res) {
  res.render('index', { title: req.params.id, template: 'project' , menu: 3});
};
