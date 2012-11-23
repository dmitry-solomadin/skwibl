
email = require 'emailjs'

cfg = require '../config'
tools = require '../tools'

smtp = email.server.connect
  user: cfg.SMTP_USER
  password: cfg.SMTP_PASSWORD
  host: cfg.SMTP_HOST
  ssl: cfg.SMTP_SSL

exports.sendRegMail = (user, fn) ->
  email = user.email
  msg = "<html>You are successfuly registred at <a href=\"#{cfg.DOMAIN}\">#{cfg.DOMAIN}</a> with  #{user.provider}.<br><br>Registration info<br>login: #{email}<br>password: #{user.password}</html>"
  return smtp.send
    text: 'enable html to see registration details'
    from: "#{cfg.DOMAIN} <#{cfg.SMTP_NOREPLY}>"
    to: "<#{email}>"
    subject: 'Registration complete'
    attachment: [
      data: msg
      alternative: on
    ]
  , (err, message) ->
    return tools.asyncOpt fn, err, user

exports.regNotify = (req, res, next, user, link) ->
  email = user.email
  msg = "<html>You are about to register at <a href=\"#{cfg.DOMAIN}\">#{cfg.DOMAIN}</a><br>Follow the link below to continue<br><a href=\"#{cfg.DOMAIN}/confirm/#{link}\">#{cfg.DOMAIN}/confirm/#{link}</a><br> or just ignore this mail to cancel registration.<br><br>Registration info<br>login: #{email}<br>password: #{user.password}</html>"
  return smtp.send
    text: 'enable html to continue registration'
    from: "#{cfg.DOMAIN} <#{cfg.SMTP_NOREPLY}>"
    to: "<#{email}>"
    subject: 'Confirm registration'
    attachment: [
      data: msg
      alternative: on
    ]
  , (err, message) ->
    if err
      req.flash 'error', "Can not send confirmation to  #{email}"
      return res.redirect '/'
    else
      req.flash 'message', "User with email: #{email}
       successfuly registred."
      return res.redirect '/checkmail'

exports.regPropose = (user, contact, link, fn) ->
  email = contact.email
  name = tools.getName user
  msg = "<html>#{name} invites you to
  <a href=\"#{cfg.DOMAIN}\">#{cfg.DOMAIN}</a><br>Follow the link below to continue<br><a href=\"  #{cfg.DOMAIN}/confirm/#{link}\">#{cfg.DOMAIN}/confirm/#{link}</a><br><br>Registration info<br>login: #{email}<br>password: #{contact.password}</html>"
  return smtp.send
    text: 'enable html to accept invitation'
    from: "#{cfg.DOMAIN} <#{cfg.SMTP_NOREPLY}>"
    to: "<#{email}>"
    subject: 'Confirm registration'
    attachment: [
      data: msg
      alternative: on
    ]
  , (err, message) ->
    if err
      return tools.asyncOpt fn, new Error "Can no send confirmation to #{email}"
    return tools.asyncOpt fn, err

exports.passwordSend = (req, res, user, next) ->
  email = user.email
  msg = "<html>Your registration info for <a href=\"#{cfg.DOMAIN}\">#{cfg.DOMAIN}</a> is<br>login: #{email}<br>password: #{user.password}</html>"
  return smtp.send
    text: 'enable html to see registration details'
    from: "#{cfg.DOMAIN} <#{cfg.SMTP_NOREPLY}>"
    to: "<#{email}>"
    subject: 'Confirm registration'
    attachment: [
      data: msg
      alternative: on
    ]
  , (err, message) ->
    next err, message
