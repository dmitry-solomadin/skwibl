var project
  , user
  , activity
  , id;

switchProject = function () {
  project = $("[name=project]:checked")[0];
  $.post('/dev/projects/get', {
    pid:project.value
  }, function (data, status, xhr) {
    var info = $('#info')
      , users = $('#projectUsers');
    info.empty();
    users.empty();
    if (status === 'success' && data) {
      for (var el in data) {
        if (el !== 'users') {
          info.append('<li>' + el + ' : ' + data[el] + '</li>');
        } else {
          data.users.forEach(function (user) {
            if (user.id !== id) {
              users.append('<input type="radio" name="user" value="' + user.id + '" onchange="switchUser()"/>' + user.displayName + '<br>');
            }
          });
        }
      }
    }
  });
};

switchUser = function () {
  user = $("[name=user]:checked")[0];
  console.log(user.value);
  console.log(project.value);
};

switchActivity = function () {
  activity = $("[name=activity]:checked")[0];
  console.log(activity.value);
};

deleteUser = function () {
  $.post('/projects/remove', {
    pid:project.value, id:user.value
  });
};

invite = function () {
  var uid = $("[name=userId]")
    , value = uid.val();
  uid.val('');
  $.post('/projects/invite', {
    uid:value,
    pid:project.value
  }, function (data, status, xhr) {
    if (status === 'success') {
      console.log('invited');
    }
  });
};

accept = function () {
  console.log('accept invitation');
  $.post('/projects/confirm', {
    aid:activity.value, answer:true
  }, function (data, status, xhr) {
    if (status === 'success') {
      console.log('accepted');
    }
  });
};

decline = function () {
  $.post('/projects/confirm', {
    aid:activity.value, answer:false
  }, function (data, status, xhr) {
    if (status === 'success') {
      console.log('declined');
    }
  });
};

$(function () {
  var projects = {
    init:function () {
      id = $("#uid").val();

      // when the client click add button
      $('#add').click(function () {
        var projectNameInput = $('#projectName')
          , projectName = projectNameInput.val();
        projectNameInput.val('');
        projectNameInput.focus();
        if (projectName != '') {
          $.post('/projects/add', {
            name:projectName
          }, function (data, status, xhr) {
            if (status === 'success' && data) {
              $('#projects').append('<input type="radio" name="project" value="' + data.id + '" onchange="switchProject()">' +
                '<a href="/dev/projects/' + data.id + '">' + data.name + '</a><br>');
            }
          });
        }
      });
    },

    deleteProject:function () {
      $.post('/projects/delete', {
        pid:project.value
      }, function (data, status, xhr) {
        if (status === 'success') {
          $("[name=project]:checked").remove();
        }
      });
    }
  };

  window.projects = projects;
})
;
