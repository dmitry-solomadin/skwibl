$(function () {
  var app = {
    initRemote:function () {
      $("a[data-remote], form[data-remote]").on("click", function () {
        var url;
        var data;
        if (this.tagName = "A") {
          url = $(this).attr("href");
        } else if (this.tagName = "FORM") {
          url = $(this).attr("action");
        }

        $.ajax({
          url:url,
          data:data,
          type:"GET",
          success:function (content) {
            $("#main-content").html(content);
          }
        });

        return false;
      })
    }
  };

  app.initRemote();

  window.App = app;
});


