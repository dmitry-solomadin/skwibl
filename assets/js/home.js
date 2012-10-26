$(function () {
  var home = {
    showLogin:function () {
      $("#loginBlock").css({
        position: 'absolute',
        top: $("#header").height() + 5,
        left: $("#signInButton").offset().left - $("#loginBlock").width() + 40
      }).fadeIn();

      $(document).on("click.login", function(event){
        if (event.target.id ==  "loginBlock" || event.target.id ==  "signInButton" ||
          $(event.target).closest("#loginBlock")[0]){
          return;
        }

        $("#loginBlock").fadeOut();
      });

      return false;
    },

    initLogin: function(){
      $("#loginForm").data("process-submit", function(data){
        home.processLogin(data);
      })
    },

    processLogin: function(data) {
      if (data == "OK") {
        window.location = "/"
      } else {
        $("#loginError").show().html(data.message);
      }
    }
  };

  home.initLogin();

  window.App.Home = home;
});


