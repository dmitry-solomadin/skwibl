
winston = require 'winston'

cfg = require '../config'

exports.setUp = (name) ->

  if cfg.ENVIRONMENT is 'development'
    infoTransport = new (winston.transports.Console)
      colorize: on
      level: "error"
    errorTransport = new (winston.transports.Console)
      colorize: on
      json: on
  else
    infoTransport = new (winston.transports.File)
      filename: "/var/log/skwibl/#{name}.log"
      maxsize: cfg.LOG_FILE_SIZE
    errorTransport = new (winston.transports.File)
      filename: "/var/log/skwibl/#{name}-exception.log"

  logger = new (winston.Logger)
    transports: [
      infoTransport
    ]
    exceptionHandlers: [
      errorTransport
    ]
    exitOnError: off
