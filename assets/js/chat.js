// Generated by CoffeeScript 1.4.0
(function() {

  $(function() {
    var Chat;
    if (!currentPage("projects/show")) {
      return;
    }
    Chat = (function() {

      function Chat() {
        this.users = [];
        this.initSockets();
      }

      Chat.prototype.fold = function(link) {
        $("#chat").animate({
          left: -305
        });
        $("#header-foldable").animate({
          width: 200
        });
        $("#canvasFooter").animate({
          paddingLeft: 0
        });
        $(".canvasFooterInner").animate({
          width: $(window).width()
        }, function() {
          return $(".canvasFooterInner").css({
            width: "100%"
          });
        });
        return $(link).attr("onclick", "App.chat.unfold(this); return false;").find("img").attr("src", "/images/room/unfold.png");
      };

      Chat.prototype.unfold = function(link) {
        $("#chat").animate({
          left: 0
        });
        $("#header-foldable").data("width", $("#header-foldable").width());
        $("#header-foldable").animate({
          width: 280
        });
        $("#canvasFooter").animate({
          paddingLeft: 300
        });
        $(".canvasFooterInner").animate({
          width: $(window).width() - 300
        }, function() {
          return $(".canvasFooterInner").css({
            width: "100%"
          });
        });
        return $(link).attr("onclick", "App.chat.fold(this); return false;").find("img").attr("src", "/images/room/fold.png");
      };

      Chat.prototype.getUserById = function(id) {
        var user, _i, _len, _ref;
        _ref = this.users;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          user = _ref[_i];
          if (user.id === id) {
            return user;
          }
        }
      };

      Chat.prototype.updateUsers = function() {
        $('#participants').empty();
        return $.each(this.users, function(key, val) {
          if (val.status === 'online') {
            return $('#participants').append("<div>" + val.id + " : " + val.displayName + " online</div>");
          } else {
            return $('#participants').append("<div>" + val.id + " : " + val.displayName + " offline</div>");
          }
        });
      };

      Chat.prototype.addMessage = function(id, message) {
        return $('#conversation-inner').append("<b>" + id + ":</b> " + message + "<br>");
      };

      Chat.prototype.initSockets = function() {
        var _this = this;
        this.chatIO = io.connect('/chat', window.copt);
        this.chatIO.on('connect', function() {
          return console.log('connect');
        });
        this.chatIO.on('connecting', function() {
          return console.log('connecting');
        });
        this.chatIO.on('connect_failed', function() {
          return console.log('connect_failed');
        });
        this.chatIO.on('disconnect', function() {
          return console.log('disconnect');
        });
        this.chatIO.on('reconnect', function() {
          return console.log('reconnect');
        });
        this.chatIO.on('reconnecting', function() {
          return console.log('reconnecting');
        });
        this.chatIO.on('reconnect_failed', function() {
          return console.log('reconnect_failed');
        });
        this.chatIO.on('error', function() {
          return console.log('error');
        });
        this.chatIO.on('message', function(data, cb) {
          return $('#conversation-inner').append("<b>" + data.id + ":</b> " + data.message.element.msg + "<br>");
        });
        this.chatIO.on('enter', function(id, cb) {
          var user;
          user = _this.getUserById(id);
          user.status = 'online';
          _this.updateUsers();
          return _this.addMessage(id, "<i>User " + id + " : " + user.displayName + " entered the project</i>");
        });
        this.chatIO.on('exit', function(id, cb) {
          var user;
          user = _this.getUserById(id);
          delete user.status;
          _this.updateUsers();
          return _this.addMessage(id, "<i>User " + id + " : " + user.displayName + " leave the project</i>");
        });
        this.chatIO.on('users', function(data) {
          _this.users = data;
          return _this.updateUsers();
        });
        return this.chatIO.on('messages', function(data) {
          var val, _i, _len, _results;
          $('#conversation-inner').empty();
          _results = [];
          for (_i = 0, _len = data.length; _i < _len; _i++) {
            val = data[_i];
            _results.push(_this.addMessage(val.owner, JSON.parse(val.data).msg));
          }
          return _results;
        });
      };

      return Chat;

    })();
    $('#chatsend').click(function() {
      var chatMessage;
      chatMessage = {
        element: {
          msg: $('#chattext').val(),
          elementId: App.room.generateId()
        }
      };
      $('#chattext').val('').focus();
      if (chatMessage.element.msg !== '') {
        App.chat.addMessage($("#uid")[0].value, chatMessage.element.msg);
        return App.chat.chatIO.emit("message", chatMessage);
      }
    });
    $('#chattext').keypress(function(e) {
      if (e.which === 13) {
        $(this).blur();
        return $('#chatsend').focus().click();
      }
    });
    return App.chat = new Chat;
  });

}).call(this);
