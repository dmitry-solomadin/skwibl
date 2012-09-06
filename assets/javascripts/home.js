$(function () {
  var home = {
    showLogin:function () {
      $("#loginBlock").css({
        position: 'absolute',
        top: $("#header").height() + 5,
        left: $("#signInButton").offset().left - $("#loginBlock").width() + 40
      }).fadeIn();

      $(document).on("click.login", function(event){
        console.log(event);
        if (event.target.id ==  "loginBlock" || event.target.id ==  "signInButton" ||
          $(event.target).closest("#loginBlock")[0]){
          return;
        }

        $("#loginBlock").fadeOut();
      });

      return false;
    }
  };

  window.App.Home = home;
});


