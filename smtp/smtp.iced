
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
  msg = "<html>Welcome to Skwibl! You are successfuly registred at <a href=\"#{cfg.DOMAIN}\">#{cfg.DOMAIN}</a> with #{user.provider}.<br><br>Your account information: <br>login: #{email}<br>password: #{user.password}</html>"
  return smtp.send
    text: "Welcome to Skwibl! You are successfuly registred at #{cfg.DOMAIN} with #{user.provider}. Your account information: login: #{email} password: #{user.password}"
    from: "#{cfg.DOMAIN} <#{cfg.SMTP_NOREPLY}>"
    to: "<#{email}>"
    subject: 'Skwibl - registration complete'
    attachment: [
      data: msg
      alternative: on
    ]
  , (err, message) ->
    return tools.asyncOpt fn, err, user

exports.regNotify = (req, res, next, user, link) ->
  email = user.email
  msg = "<html>You are about to register at <a href=\"#{cfg.DOMAIN}\">#{cfg.DOMAIN}</a><br>To finish your registration, go to:<br><a href=\"#{cfg.DOMAIN}/confirm/#{link}\">#{cfg.DOMAIN}/confirm/#{link}</a><br>.<br><br>Your account information<br>Login: #{email}<br>Password: #{user.password}</html>"
  return smtp.send
    text: "You are about to register at #{cfg.DOMAIN} To finish your registration, go to:#{cfg.DOMAIN}/confirm/#{link}. Your account information Login: #{email} Password: #{user.password}"
    from: "#{cfg.DOMAIN} <#{cfg.SMTP_NOREPLY}>"
    to: "<#{email}>"
    subject: 'Skwibl - confirm registration'
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
  msg = "<html>#{name} invites you to <a href=\"#{cfg.DOMAIN}\">#{cfg.DOMAIN}</a><br>To finish your registration, go to:<br><a href=\"#{cfg.DOMAIN}/confirm/#{link}\">#{cfg.DOMAIN}/confirm/#{link}</a><br><br>Registration info<br>login: #{email}<br>password: #{contact.password}</html>"
  return smtp.send
    text: "#{name} invites you to #{cfg.DOMAIN} To finish your registration, go to: #{cfg.DOMAIN}/confirm/#{link} Registration info login: #{email} password: #{contact.password}"
    from: "#{cfg.DOMAIN} <#{cfg.SMTP_NOREPLY}>"
    to: "<#{email}>"
    subject: 'Skwibl - confirm invitation'
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
    text: "Your registration info for #{cfg.DOMAIN}  is login: #{email} password: #{user.password}"
    from: "#{cfg.DOMAIN} <#{cfg.SMTP_NOREPLY}>"
    to: "<#{email}>"
    subject: 'Skwibl - password sent'
    attachment: [
      data: msg
      alternative: on
    ]
  , (err, message) ->
    next err, message
