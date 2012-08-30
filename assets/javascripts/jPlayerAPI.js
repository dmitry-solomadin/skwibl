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
        live: true,
        onTrigger:function () {
          $(bookmark).popover('show');
        },
        offTrigger:function () {
          $(bookmark).popover('hide');
        }
      });

//      $(bookmark).mouseenter(function () {
//        $(this).popover('show');
//      }).mouseleave(function () {
//          $(this).popover('hide');
//        })
    }
  };

  window.App.jplayerAPI = api;
});


