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
      var draggedObject = $('.draggable');
      if (draggedObject[0] && opt.onAfterDrag) {
        opt.onAfterDrag();
      }

      draggedObject.removeClass('draggable');
    });

    $(document).on("mousemove", function (e) {
      if (!$el.hasClass("draggable")) {
        return;
      }

      if (!$el.data("pdx")) {
        $el.data("pdx", e.clientX);
        $el.data("pdy", e.clientY);
      } else {
        var dx = e.clientX - parseInt($el.data("pdx")),
          dy = e.clientY - parseInt($el.data("pdy"));

        $el.data("pdx", e.clientX);
        $el.data("pdy", e.clientY);

        opt.onDrag(dx, dy);
      }
    });

    $el.css('cursor', opt.cursor).on("mousedown", function (e) {
      $el.addClass('draggable');
      $el.data("pdx", "");
      $el.data("pdy", "");
      e.preventDefault(); // disable selection
    });

    return $el;
  }
})(jQuery);

function isMac() {
  return /Mac/.test(navigator.userAgent);
}

function currentPage(template) {
  return $("#currentTemplate").val() == template
}