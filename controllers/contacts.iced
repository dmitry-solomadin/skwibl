#
# GET
# Get contact list
#
exports.get = (req, res, next) =>
  @db.contacts.get req.user.id, (err, contacts) =>
    unless err
      return res.render 'index', contacts: contacts
    return next err
