exports.aboutUs = (req, res, next) =>
  return res.render 'index', template: 'public/about_us'

exports.contacts = (req, res, next) =>
  return res.render 'index', template: 'public/contacts'

exports.team = (req, res, next) =>
  return res.render 'index', template: 'public/team'

exports.tour = (req, res, next) =>
  return res.render 'index', template: 'public/tour'

exports.tourCapter = (req, res) =>
  res.send 'tour'
