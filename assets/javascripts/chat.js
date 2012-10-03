var copt = {
  'connect timeout': 5000,
  'max reconnection attempts': 5,
//   'force new connection': true
};

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
  console.log(id);
});

chat.on('exit', function(id, cb) {
  console.log(id);
});

chat.on('users', function(data) {
  console.log(data);
  $('#users').empty();
  $.each(data, function(key, val) {
    $('#users').append('<div>' + val + '</div>');
  });
});

chat.on('messages', function(data) {
  $('#conversation').empty();
  data.forEach(function(val) {
    addMessage(val.owner, val.data);
  });
});

switchProject = function() {
  var project = $("[name=project]:checked")[0];
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
