$(function () {
  var app = {
    initRemote:function () {
      $("form[data-remote]").on("submit", function () {
        var data = {};
        $(this).find("input").each(function () {
          data[$(this).attr("name")] = $(this).val();
        });

        var onsuccess = $(this).data("process-submit") ? $(this).data("process-submit") : function (data) {
          $("#main-content").html(data);
        };

        $.ajax({
          url:$(this).attr("action"),
          data:data,
          type:"POST",
          success:onsuccess
        });

        return false;
      });

      $("a[data-remote]").on("click", function () {
        $.ajax({
          url:$(this).attr("href"),
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


