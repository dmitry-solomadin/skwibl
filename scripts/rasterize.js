var system = require('system');
var webpage = require('webpage');
var page = webpage.create();
var link = encodeURI(system.args[1]);
var output = system.args[2];
page.viewportSize = {
  width: system.args[3],
  height: system.args[4],
  margin: '0px'
};
page.open(link, function () {
  window.setTimeout(function() {
    page.render(output);
    phantom.exit();
  }, 200);
});
