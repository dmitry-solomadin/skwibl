cluster = require 'cluster'
os = require 'os'
fs = require 'fs'
gm = require 'gm'
crypto = require 'crypto'
validator = require 'validator'
generatePassword = require 'password-generator'
_ = require 'lodash'

cfg = require '../config'

numCPUs = os.cpus().length

exports.isEmail = (value) ->
  try
    validator.check(value).len(6,64).isEmail()
    return true
  catch error
    return false

exports.sanitize = validator.sanitize

exports.emailUid = (x) ->
  return "emails:#{x}:uid"

exports.hash = (email) ->
  hash = crypto.createHash 'md5'
  hash.update Date() + email, 'ascii'
  return hash.digest 'hex'

exports.genPass = ->
  return generatePassword.call null, cfg.PASSWORD_LENGTH, cfg.PASSWORD_EASYTOREMEMBER

exports.purify = (obj) ->
  return null if not obj
  for prop of obj
    delete obj[prop] if not obj[prop]
  return null if _.isEmpty obj
  return obj

exports.getName = (user) ->
  if user.name
    name = user.name
    if name.givenName and name.familyName
      return "#{name.givenName} #{name.familyName}"
    if name.givenName
      return name.givenName
    if name.familyName
      return name.familyName
  if user.displayName
    return user.displayName
  return user.emails[0].value

exports.returnStatus = (err, res) ->
  return res.send true if not err
  res.send false

exports.getFileMime = (ext) ->
  extension = ext.toLowerCase()
  image = cfg.MIME[0][extension]
  video = cfg.MIME[1][extension]
  if image
    return image
  return video

exports.isMimeSupported = (mimeToTest) ->
  for mimeBucket in cfg.MIME
    for ext of mimeBucket
      mime = mimeBucket[ext]
      return true if mime == mimeToTest
  return false

exports.getFileType = (mime) ->
  return null if not mime
  return mime.split('/')[0]

exports.makeProjectThumbs = (pid, element, fn) ->
  type = @getFileType element.mime
  if type is 'image'
    path = "#{cfg.UPLOADS}/#{pid}/image"
    #TODO make this async
    for size, rect of cfg.PROJECT_THUMB_SIZE
      gm("#{path}/#{element.name}")
      .resize(rect.width, rect.height)
      .noProfile()
      .write "#{path}/#{size}/#{element.name}", (err) =>
        return @asyncOpt fn, err, element

exports.include = (dir, fn, defaults) ->
  for name in fs.readdirSync(dir)
    shortName = name.split('.')[0]
    ext = name.split('.')[1]
    isModule = shortName isnt 'index' and ( ext is 'js' or ext is 'coffee' or ext is 'iced' )
    if isModule
      mod = require dir + '/' + name
      _.extend mod, defaults
      fn mod, shortName

exports.asyncOpt = (fn, err, val)->
  process.nextTick(-> fn err, val) if fn

exports.asyncOptError = (fn, msg, val) ->
  process.nextTick(->
    fn
      error: true
      msg: msg
    , val
  ) if fn

exports.asyncOrdered = (array, index, fn, done) ->
  index = index or 0
  return done() if index is array.length
  fn(array[index])
  process.nextTick ->
    exports.asyncOrdered array, index++, fn, done

exports.asyncParallel = (array, fn) ->
  array.left = array.length
  for el, index in array
    ((val, index) ->
      process.nextTick ->
        fn val, index
    )(el, index)

exports.asyncDone = (array, fn) ->
  --array.left
  process.nextTick(fn) if array.left is 0

exports.exitNotify = (worker, code, signal) ->
  console.log "Worker #{worker.id} died: #{worker.process.pid}"

exports.startCluster = (stop, start) ->
  if cluster.isMaster
    cluster.fork() while numCPUs--
    cluster.on 'exit', (worker, code, signal) ->
#       clearInterval t
      stop worker, code, signal
  else
#     fn = -> gc()
#     t = setInterval fn, cfg.GC_INTERVAL
    start cluster

exports.addError = (req, text, id) ->
  req.flash "objectErrors", {text: text, id: id} # it will add error object to flash array

exports.sendError = (res, err) ->
  if err
    return res.send err if err.error
    return res.send false

exports.logError = (err, val) ->
  console.trace err if err
