
moment = require 'moment'

cfg = require '../config'

#TODO separate on submodules

exports.currentUser = (id) ->
  return id is @req.user.id if id
  return @req.user

exports.flashError = ->
  return @req.flash 'error'

exports.flashMessage = ->
  return @req.flash 'message'

exports.flashWarning = ->
  return @req.flash 'warning'

exports.errorMessages = ->
  return @req.flash 'objectErrors'

exports.isProduction = ->
  return cfg.ENVIRONMENT is 'production'

exports.getDropboxKey = -> cfg.DROPBOX_APP_KEY

# todo move this to helpers/comments.iced
exports.splitComments = (messages) ->
  yesterday = moment().subtract("days", 1).endOf("day")
  today = moment()

  timeRanges = [
    { name: "Today", id: "today", start: moment(), messages: [] },
    { name: "1 day", id: "day1", start: moment().subtract("days", 1).startOf("day"), messages: [] },
    { name: "1 week", id: "week1", start: moment().subtract("weeks", 1).startOf("day"), messages: [] },
    { name: "2 week", id: "week2", start: moment().subtract("weeks", 2).startOf("day"), messages: [] },
    { name: "1 month", id: "month1", start: moment().subtract("months", 1).startOf("day"), messages: [] }
  ]

  uniqueDates = {}
  for message in messages
    messageTime = moment parseFloat(message.time)
    endOfDayMessageTime = moment(parseFloat(message.time)).endOf("day")

    message.date = messageTime.format("MMM DD, YYYY")
    dayDiff = Math.abs endOfDayMessageTime.diff(today.endOf("day"), "days")
    switch dayDiff
      when 0 then prettyName = "Today"
      when 1 then prettyName = "Yesterday"
    uniqueDates[message.date] =
      enabled: true
      prettyName: prettyName

    for timeRange in timeRanges
      messageUnixTime = messageTime.unix()
      if messageUnixTime > yesterday.unix()
        timeRanges[0].messages.push message
        break

      if yesterday.unix() > messageUnixTime > timeRange.start.unix()
        timeRange.messages.push message
        break

  timeRanges: timeRanges
  uniqueDates: uniqueDates
