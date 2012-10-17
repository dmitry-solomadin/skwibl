$(function () {
  if (!currentPage("projects/show")) {
    return;
  }

  var users = [];

  var chat = {
    fold:function (link) {
      $("#chat").animate({left:-305});
      $("#header-foldable").animate({width:125});
      $("#canvasFooter").animate({marginLeft:0});

      $(link).attr("onclick", "window.chat.unfold(this); return false;");
      $(link).html(">>");
    },

    unfold:function (link) {
      $("#chat").animate({left:0});
      $("#header-foldable").data("width", $("#header-foldable").width());
      $("#header-foldable").animate({width:280});
      $("#canvasFooter").animate({marginLeft:300});

      $(link).attr("onclick", "window.chat.fold(this); return false;");
      $(link).html("<<");
    },

    getUserById:function (id) {
      for (var i = 0, len = users.length; i < len; i++) {
        if (users[i].id === id) {
          return users[i];
        }
      }
    },

    updateUsers:function () {
      $('#participants').empty();
      $.each(users, function (key, val) {
        if (val.status === 'online') {
          $('#participants').append('<div>' + val.id + ' : ' + val.displayName + ' : online</div>');
        } else {
          $('#participants').append('<div>' + val.id + ' : ' + val.displayName + ' : offline</div>');
        }
      });
    },

    addMessage:function (id, message) {
      $('#conversation-inner').append('<b>' + id + ':</b> ' + message + '<br>');
    }
  };

  // CHAT IO
  var chatIO = io.connect('/chat', window.copt);

  chatIO.on('connect', function () {
    console.log('connect');
  });

  chatIO.on('connecting', function () {
    console.log('connecting');
  });

  chatIO.on('connect_failed', function () {
    console.log('connect_failed');
  });

  chatIO.on('disconnect', function () {
    console.log('disconnect');
  });

  chatIO.on('reconnect', function () {
    console.log('reconnect');
  });

  chatIO.on('reconnecting', function () {
    console.log('reconnecting');
  });

  chatIO.on('reconnect_failed', function () {
    console.log('reconnect_failed');
  });

  chatIO.on('error', function () {
    console.log('error');
  });

  chatIO.on('message', function (data, cb) {
    $('#conversation-inner').append('<b>' + data.id + ':</b> ' + data.message + '<br>');
  });

  chatIO.on('enter', function (id, cb) {
    var user = window.chat.getUserById(id);
    user.status = 'online';
    window.chat.updateUsers();
    window.chat.addMessage(id, '<i>User ' + id + ' : ' + user.displayName + ' entered the project</i>');
  });

  chatIO.on('exit', function (id, cb) {
    var user = window.chat.getUserById(id);
    delete user.status;
    window.chat.updateUsers();
    window.chat.addMessage(id, '<i>User ' + id + ' : ' + user.displayName + ' leave the project</i>');
  });

  chatIO.on('users', function (data) {
    users = data;
    window.chat.updateUsers();
  });

  chatIO.on('messages', function (data) {
    $('#conversation-inner').empty();
    data.forEach(function (val) {
      window.chat.addMessage(val.owner, val.data);
    });
  });

  // when the client clicks SEND
  $('#chatsend').click(function () {
    var message = $('#chattext').val()
      , id = $("#uid")[0].value;
    $('#chattext').val('');
    $('#chattext').focus();
    if (message !== '') {
      window.chat.addMessage(id, message);
      chatIO.send(message);
    }
  });

  // when the client hits ENTER on the keyboard
  $('#chattext').keypress(function (e) {
    if (e.which == 13) {
      $(this).blur();
      $('#chatsend').focus().click();
    }
  });

  window.chat = chat;
});

