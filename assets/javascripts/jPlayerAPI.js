$(function () {
  var api = {
    addBookmark:function (jplayerSelector) {
      var jplayer = $(jplayerSelector);
      var jplayerContainer = jplayer.closest(".jp-container");
      var playPercent = jplayer.data("jPlayer").status.currentPercentAbsolute;
      var timePlayed = jplayer.data("jPlayer").status.currentTime.toFixed(2);
      var bookmark = $(
        "<div class='jp-bookmark' style='left:" + playPercent + "%;'>&nbsp;</div>"
      );

      jplayerContainer.find(".jp-play-bar").append(bookmark);

      var popoverContent = $("<div class='jp-bookmark-content' onmouseover=''><div class='add-comment'></div></div>");

      $(bookmark).popover({
        title:timePlayed,
        trigger:'manual',
        animation:false,
        placement:'bottom',
        content:popoverContent
      });

      $(bookmark).combinedHover({
        additionalTriggers:".popover",
        live:true,
        onTrigger:function () {
          $(bookmark).popover('show');
        },
        offTrigger:function () {
          $(bookmark).popover('hide');
        }
      });
    },

    snapshot:function (jplayerSelector) {
      var video = $(jplayerSelector)[0];
      var canvas = $('<canvas></canvas>')[0];

      var ratio = 54 / video.videoHeight;

      canvas.width = ratio * video.videoWidth;
      canvas.height = 54;
      var ctx = canvas.getContext('2d');
      ctx.drawImage(video, 0, 0, video.videoWidth, video.videoHeight, 0, 0, canvas.width, canvas.height);

      return canvas.toDataURL('image/jpeg');
    },

    initAdditionalToolbar:function (jplayerSelector) {
      var jplayer = $(jplayerSelector);
      var jplayerContainer = jplayer.closest(".jp-container");

      var additionalSeekBar = jplayerContainer.find(".jp-additional-seek-bar");

    }
  };

  window.App.jplayerAPI = api;
});


