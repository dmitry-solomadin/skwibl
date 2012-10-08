var copt = {
  'connect timeout': 5000,
  'max reconnection attempts': 5,
//   'force new connection': true
};

var users = [];

var projectsRe = /\/dev\/projects\/[\d]+/
  , path = window.location.pathname;

getUserById = function(id) {
  for(var i = 0, len = users.length; i < len; i++) {
    if(users[i].id === id) {
      return users[i];
    }
  }
};

updateUsers = function() {
  $('#users').empty();
  $.each(users, function(key, val) {
    if(val.status === 'online') {
      $('#users').append('<div>' + val.id + ' : ' + val.displayName + ' : online</div>');
    } else {
      $('#users').append('<div>' + val.id + ' : ' + val.displayName + ' : offline</div>');
    }
  });
};

if(projectsRe.test(path)) {
  var chat = io.connect('/chat', copt);

  chat.on('connect', function() {
    console.log('connect');
  });

  chat.on('connecting', function() {
    console.log('connecting');
  });

  chat.on('connect_failed', function() {
    console.log('connect_failed');
  });

  chat.on('disconnect', function() {
    console.log('disconnect');
  });

  chat.on('reconnect', function() {
    console.log('reconnect');
  });

  chat.on('reconnecting', function() {
    console.log('reconnecting');
  });

  chat.on('reconnect_failed', function() {
    console.log('reconnect_failed');
  });

  chat.on('error', function() {
    console.log('error');
  });

  chat.on('message', function(data, cb) {
    $('#conversation').append('<b>'+ data.id + ':</b> ' + data.message + '<br>');
  });

  chat.on('enter', function(id, cb) {
    var user = getUserById(id);
    user.status = 'online';
    updateUsers();
    addMessage(id, '<i>User ' + id + ' : ' + user.displayName + ' entered the project</i>');
  });

  chat.on('exit', function(id, cb) {
    var user = getUserById(id);
    delete user.status;
    updateUsers();
    addMessage(id, '<i>User ' + id + ' : ' + user.displayName + ' leave the project</i>');
  });

  chat.on('users', function(data) {
    users = data;
    updateUsers();
  });

  chat.on('messages', function(data) {
    $('#conversation').empty();
    data.forEach(function(val) {
      addMessage(val.owner, val.data);
    });
  });

  switchChatProject = function() {
    var project = $("[name=project]:checked")[0];
    $('#conversation').empty();
    chat.emit('switch', project.value);
  };

  addMessage = function(id, message) {
    $('#conversation').append('<b>'+ id + ':</b> ' + message + '<br>');
  };

  $(function(){
    // when the client clicks SEND
    $('#datasend').click(function() {
      var message = $('#data').val()
	, id = $("#id")[0].value;
      $('#data').val('');
      $('#data').focus();
      if(message !== '') {
	addMessage(id, message);
	chat.send(message);
      }
    });

    // when the client hits ENTER on the keyboard
    $('#data').keypress(function(e) {
      if(e.which == 13) {
	$(this).blur();
	$('#datasend').focus().click();
      }
    });
  });

}
