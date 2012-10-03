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

  $.fn.drags = function (opt) {
    opt = $.extend({cursor:"move"}, opt);
    var $el = this;

    $(document).on("mouseup", function () {
      $('.draggable').removeClass('draggable');
    });

    return $el.css('cursor', opt.cursor).on("mousedown", function (e) {
      var $drag = $(this).addClass('draggable');

      $drag.css('z-index', 1000).parents().on("mousemove", function (e) {
        if (!$drag.data("pdx")) {
          $drag.data("pdx", e.clientX);
          $drag.data("pdy", e.clientY);
        } else {
          var dx = e.clientX - parseInt($drag.data("pdx")),
            dy = e.clientY - parseInt($drag.data("pdy"));

          $drag.data("pdx", e.clientX);
          $drag.data("pdy", e.clientY);

          if ($drag.hasClass("draggable")) {
            opt.onDrag(dx, dy);
          }
        }
      });

      e.preventDefault(); // disable selection
    });
  }
})(jQuery);