$(function () {
  var notificator = {

    init:function () {
      this.notification = $("<div id='notification' class='notification'></div>");
      $("body").append(this.notification);
    },

    notify:function (text) {
      this.notification.html(text);
      this.show();
    },

    show:function () {
      this.notification.css({right:50, top:30});
      this.notification.animate({
        opacity:1,
        top:60
      }, function () {
        window.setTimeout(function () {
          window.notificator.hide();
        }, 2000);
      })
    },

    hide:function () {
      this.notification.animate({opacity:0});
    }

  };

  notificator.init();
  window.notificator = notificator;
});