cfg = require '../config'

exports.currentUser = (id) ->
  return id is this.req.user.id if id
  return this.req.user

exports.flashError = ->
  return this.req.flash 'error'

exports.flashMessage = ->
  return this.req.flash 'message'

exports.flashWarning = ->
  return this.req.flash 'warning'

exports.errorMessages = ->
  return this.req.flash 'objectErrors'

exports.isProduction = ->
  console.log "QHWEKQWEJKQWELKWQJEKLJQWE", cfg.ENVIRONMENT
  return cfg.ENVIRONMENT is 'production'

exports.splitComments = (messages) ->
  # rangeEnd is always the end of yesterday
  yesterday = @moment().subtract("days", 1).endOf("day")

  timeRanges = [
    { name: "Today", id: "today", start: @moment(), messages: [] },
    { name: "1 day", id: "day1", start: @moment().subtract("days", 1).startOf("day"), messages: [] },
    { name: "1 week", id: "week1", start: @moment().subtract("weeks", 1).startOf("day"), messages: [] },
    { name: "2 week", id: "week2", start: @moment().subtract("weeks", 2).startOf("day"), messages: [] },
    { name: "1 month", id: "month1", start: @moment().subtract("months", 1).startOf("day"), messages: [] }
  ]

  for message in messages
    for timeRange in timeRanges
      messageTime = @moment(parseFloat(message.time)).unix()
      if messageTime > yesterday.unix()
        timeRanges[0].messages.push message
        break;

      if yesterday.unix() > messageTime > timeRange.start.unix()
        timeRange.messages.push message
        break;

  timeRanges
