$ ->
  api =
    addBookmark: (jplayerSelector) ->
      jplayer = $(jplayerSelector)
      jplayerContainer = jplayer.closest(".jp-container")
      playPercent = jplayer.data("jPlayer").status.currentPercentAbsolute
      timePlayed = jplayer.data("jPlayer").status.currentTime.toFixed(2)
      bookmark = $("<div class='jp-bookmark' style='left:#{playPercent}%;'>&nbsp;</div>")

      jplayerContainer.find(".jp-play-bar").append(bookmark)

      popoverContent = $("<div class='jp-bookmark-content' onmouseover=''><div class='add-comment'></div></div>")

      $(bookmark).popover
        title: timePlayed
        trigger: 'manual'
        animation: false
        placement: 'bottom'
        content: popoverContent

      $(bookmark).combinedHover
        additionalTriggers: ".popover"
        live: true
        onTrigger: -> $(bookmark).popover('show')
        offTrigger: -> $(bookmark).popover('hide')

    snapshot: (jplayerSelector) ->
      video = $(jplayerSelector)[0]
      canvas = $('<canvas></canvas>')[0]

      ratio = 54 / video.videoHeight

      canvas.width = ratio * video.videoWidth
      canvas.height = 54
      ctx = canvas.getContext('2d')
      ctx.drawImage(video, 0, 0, video.videoWidth, video.videoHeight, 0, 0, canvas.width, canvas.height)

      canvas.toDataURL('image/jpeg')

    initAdditionalToolbar: (jplayerSelector) ->
      jplayer = $(jplayerSelector)
      jplayerContainer = jplayer.closest(".jp-container")

      additionalSeekBar = jplayerContainer.find(".jp-additional-seek-bar")

  App.jplayerAPI = api
