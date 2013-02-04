path = require 'path'
email = require 'emailjs'
emailTemplates = require 'email-templates'
templatesDir = path.resolve(__dirname, "templates")

cfg = require '../config'
tools = require '../tools'

smtp = email.server.connect
  user: cfg.SMTP_USER
  password: cfg.SMTP_PASSWORD
  host: cfg.SMTP_HOST
  ssl: cfg.SMTP_SSL

emailTemplates templatesDir, (err, template) ->

  exports.sendRegMail = (user, fn) ->
    email = user.email
    locals =
      domain: cfg.DOMAIN
      provider: user.provider
      email: email
      password: user.password
    template 'welcome', locals, (err, html, text) ->
      return smtp.send
        text: text
        from: "Skwibl <#{cfg.SMTP_NOREPLY}>"
        to: "<#{email}>"
        subject: 'Skwibl — registration complete'
        attachment: [
          data: html
          alternative: on
        ]
      , (err, message) ->
        return tools.asyncOpt fn, err, user

  exports.regConfirm = (user, link, fn) ->
    email = user.email
    locals =
      domain: cfg.DOMAIN
      provider: user.provider
      email: email
      link: link
      password: user.password
    template 'regConfirm', locals, (err, html, text) ->
      return smtp.send
        text: text
        from: "Skwibl <#{cfg.SMTP_NOREPLY}>"
        to: "<#{email}>"
        subject: 'Skwibl — confirm registration'
        attachment: [
          data: html
          alternative: on
        ]
      , (err, message) ->
        return tools.asyncOpt fn, err, message

  exports.regPropose = (user, contact, link, fn) ->
    email = contact.email
    name = tools.getName user
    locals =
      domain: cfg.DOMAIN
      provider: user.provider
      email: email
      name: name
      password: contact.password
      link: link
    template 'regPropose', locals, (err, html, text) ->
      return smtp.send
        text: text
        from: "Skwibl <#{cfg.SMTP_NOREPLY}>"
        to: "<#{email}>"
        subject: 'Skwibl — confirm invitation'
        attachment: [
          data: html
          alternative: on
        ]
      , (err, message) ->
        if err
          return tools.asyncOpt fn, new Error "Cannot send confirmation to #{email}"
        return tools.asyncOpt fn, err

  exports.passwordSend = (user, fn) ->
    email = user.email
    locals =
      domain: cfg.DOMAIN
      email: email
      password: user.password
    template 'passwordSend', locals, (err, html, text) ->
      return smtp.send
        text: text
        from: "Skwibl <#{cfg.SMTP_NOREPLY}>"
        to: "<#{email}>"
        subject: 'Skwibl — password sent'
        attachment: [
          data: html
          alternative: on
        ]
      , (err, message) ->
        return tools.asyncOpt fn, err, message

  exports.prjInviteActivity = (user, invitor, project, fn) ->
    email = user.email
    name = tools.getName invitor
    locals =
      domain: cfg.DOMAIN
      project: project
      name: name
    template 'prjInviteActivity', locals, (err, html, text) ->
      return smtp.send
        text: text
        from: "Skwibl <#{cfg.SMTP_NOREPLY}>"
        to: "<#{email}>"
        subject: "Skwibl — #{name} invites you to discuss a project online."
        attachment: [
          data: html
          alternative: on
        ]
      , (err, message) ->
        return tools.asyncOpt fn, err, message
