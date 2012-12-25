
db = require '../db'

exports.configure = (sio) ->

  activities = sio.of '/activities'

  activities.on 'connection', (socket) ->

    hs = socket.handshake
    id = hs.user.id

    socket.join "activities#{id}"

    db.activities.getAllNew id, (err, activities) ->
      socket.emit "init", activities.length

    socket.on 'disconnect', ->
      console.log 'disconnect'
