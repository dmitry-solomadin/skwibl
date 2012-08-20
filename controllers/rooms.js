/******************************************
 *             ROOM MANAGEMENT            *
 ******************************************/

/*
 * GET
 * Get all rooms
 */
exports.rooms = function(req, res) {
  res.render('index', { title: req.params.id, template: 'room' , menu: 3});
};

/*
 * GET
 * Enter the room
 */
exports.room = function(req, res) {
  res.render('index', { title: req.params.id, template: 'room' , menu: 3});
};
