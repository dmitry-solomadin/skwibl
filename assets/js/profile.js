
var connections = [];

getUserById = function(id) {
  for(var i = 0, len = users.length; i < len; i++) {
    if(users[i].id === id) {
      return users[i];
    }
  }
};

updateConnections = function() {
  $('#users').empty();
  $.each(users, function(key, val) {
    if(val.status === 'online') {
      $('#users').append('<div>' + val.id + ' : ' + val.displayName + ' : online</div>');
    } else {
      $('#users').append('<div>' + val.id + ' : ' + val.displayName + ' : offline</div>');
    }
  });
};

connect = function(provider) {
  window.location = '/connect/' + provider;
};

disconnect = function(provider) {
  $.post('/auth/disconnect', {
    provider: provider
  }, function(data, status, xhr) {
    if(status === 'success') {
      var facebook = $("#" + provider);
      facebook.empty();
      facebook.html('disconnected');
    }
  });
};
