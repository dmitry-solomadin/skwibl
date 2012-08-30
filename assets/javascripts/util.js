(function ($) {
  $.fn.combinedHover = function (settings) {
    var trigger = this;
    var additionalTriggers = settings.additionalTriggers;

    trigger[0].hovercount = 0;

    if (settings.live) {
      $(document).on('mouseenter', additionalTriggers,
        function () {
          addHoverCount();
        }).on('mouseleave', additionalTriggers, function () {
          removeHoverCount();
        });
    } else {
      additionalTriggers.on('mouseenter',
        function () {
          addHoverCount();
        }).on('mouseleave', function () {
          removeHoverCount();
        });
    }

    trigger.on('mouseenter',
      function () {
        addHoverCount();

        settings.onTrigger();
      }).on('mouseleave', function () {
        removeHoverCount();
      });

    function addHoverCount() {
      updateHoverCount(1);
    }

    function removeHoverCount() {
      updateHoverCount(-1);

      setTimeout(function () {
        if (trigger[0].hovercount == 0) {
          settings.offTrigger();
        }
      }, 100);
    }

    function updateHoverCount(toAdd) {
      trigger[0].hovercount = trigger[0].hovercount + toAdd
    }
  };
})(jQuery);