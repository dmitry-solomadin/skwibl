$(function () {
  var opts = {
    paper:undefined,
    tool:undefined,
    selectedTool:undefined,
    historytools:[],
    tooltype:'line',
    historyCounter:undefined,
    color:'#000',
    strokeWidth:5,
    opacity:1
  };

  var room = {
    init:function (canvas, opt) {
      var options = $.extend({}, opts, opt);
      opts = options;
      this.createTool(new opts.paper.Path());

      $("#toolSelect > li, #panTool, #selectTool").on("click", function () {
        window.room.setTooltype($(this).data("tooltype"));
      });

      $('.color').click(function () {
        $('.color').removeClass('activen');
        opts.color = $(this).attr('data-color');
        $(this).addClass('activen');
      });

      this.initUploader();

      return false;
    },

    createTool:function (tool, settings) {
      if (!settings) {
        settings = {};
      }

      opts.tool = tool;
      opts.tool.strokeColor = settings.color ? settings.color : opts.color;
      opts.tool.strokeWidth = settings.width ? settings.width : opts.strokeWidth;
      opts.tool.opacity = settings.opacity ? settings.opacity : opts.opacity;
      opts.tool.dashArray = settings.dashArray ? settings.dashArray : undefined;
    },

    setTooltype:function (tooltype) {
      opts.tooltype = tooltype;
    },

    onMouseMove:function (canvas, event) {
      $(canvas).css({cursor:"default"});

      if (opts.selectedTool && opts.selectedTool.selectionRect) {
        if (opts.selectedTool.selectionRect.bottomRightRect.bounds.contains(event.point)) {
          $(canvas).css({cursor:"se-resize"});
        } else if (opts.selectedTool.selectionRect.topLeftRect.bounds.contains(event.point)) {
          $(canvas).css({cursor:"nw-resize"});
        }
      }
    },

    onMouseDown:function (canvas, event) {
      $("#removeSelected").addClass("disabled");
      if (opts.selectedTool && opts.selectedTool.selectionRect) {
        opts.selectedTool.selectionRect.remove();
      }

      if (opts.tooltype == 'line') {
        this.createTool(new opts.paper.Path());
      } else if (opts.tooltype == 'highligher') {
        this.createTool(new opts.paper.Path(), {color:opts.color, width:15, opacity:0.7});
      } else if (opts.tooltype == 'straightline') {
        this.createTool(new opts.paper.Path());
        if (opts.tool.segments.length == 0) {
          opts.tool.add(event.point);
        }
        opts.tool.add(event.point);
      } else if (opts.tooltype == "select") {
        var selectedSomething = false;
        $(window.room.getHistoryTools()).each(function () {
          if (this.bounds.contains(event.point)) {
            opts.selectedTool = this;
            selectedSomething = true;
          }
        });

        if (opts.selectedTool && opts.selectedTool.selectionRect &&
          opts.selectedTool.selectionRect.bounds.contains(event.point)) {
          selectedSomething = true;
        }

        if (!selectedSomething) {
          opts.selectedTool = null;
        }

        if (opts.selectedTool) {
          opts.selectedTool.selectionRect = window.room.helper.createSelectionRectangle(opts.selectedTool);
          $("#removeSelected").removeClass("disabled");

          if (opts.selectedTool.selectionRect.topLeftRect.bounds.contains(event.point)) {
            opts.selectedTool.scalersSelected = "topLeft"
          } else if (opts.selectedTool.selectionRect.bottomRightRect.bounds.contains(event.point)) {
            opts.selectedTool.scalersSelected = "bottomRight"
          } else {
            opts.selectedTool.scalersSelected = false;
          }

          if (opts.selectedTool.selectionRect.removeButton.bounds.contains(event.point)) {
            window.room.removeSelected();
          }
        }
      }

      /* this should be*/
      if (opts.tooltype == 'line' || opts.tooltype == 'straightline' || opts.tooltype == 'highligher') {
        this.addHistoryTool();
      }
    },

    onMouseDrag:function (canvas, event) {
      if (opts.tooltype == 'line') {
        this.addPoint(event.point);
        opts.tool.smooth();
      } else if (opts.tooltype == 'highligher') {
        this.addPoint(event.point);
        opts.tool.smooth();
      } else if (opts.tooltype == 'circle') {
        var radius = (event.downPoint - event.point).length;
        this.createTool(new opts.paper.Path.Circle(event.downPoint, radius));
        opts.tool.removeOnDrag();
      } else if (opts.tooltype == 'rectangle') {
        var sizes = event.downPoint - event.point;
        var rectangle = new opts.paper.Rectangle(event.point.x, event.point.y, sizes.x, sizes.y);
        this.createTool(new opts.paper.Path.Rectangle(rectangle));
        opts.tool.removeOnDrag();
      } else if (opts.tooltype == 'straightline') {
        opts.tool.lastSegment.point = event.point;
      } else if (opts.tooltype == 'pan') {
        console.log(opts.paper.project.activeLayer.children);
        $(opts.paper.project.activeLayer.children).each(function () {
          if (this.translate) {
            this.translate(event.delta);
          }
        })
      } else if (opts.tooltype == 'select') {
        if (opts.selectedTool) {
          if (opts.selectedTool.scalersSelected) {
            var deltaPart = (event.delta.x + event.delta.y) / 200;
            if (opts.selectedTool.scalersSelected == 'topLeft') {
              deltaPart = -deltaPart;
            }
            var delta = 1 + deltaPart;

            opts.selectedTool.scale(delta);

            var previousPoint = new Point(opts.selectedTool.selectionRect.theRect.bounds.x, opts.selectedTool.selectionRect.theRect.bounds.y);
            opts.selectedTool.selectionRect.theRect.scale(delta);
            var nextPoint = new Point(opts.selectedTool.selectionRect.theRect.bounds.x, opts.selectedTool.selectionRect.theRect.bounds.y);

            opts.selectedTool.selectionRect.topLeftRect.translate(nextPoint - previousPoint);
            opts.selectedTool.selectionRect.bottomRightRect.translate(previousPoint - nextPoint);
            opts.selectedTool.selectionRect.removeButton.position = new Point(
              opts.selectedTool.selectionRect.theRect.bounds.x + opts.selectedTool.selectionRect.theRect.bounds.width,
              opts.selectedTool.selectionRect.theRect.bounds.y);
          } else {
            opts.selectedTool.translate(event.delta);

            if (opts.selectedTool.selectionRect) {
              opts.selectedTool.selectionRect.translate(event.delta);
            }
          }
        }
      }
    },

    onMouseUp:function (canvas, event) {
      if (opts.tooltype == 'line') {
        this.addPoint(event.point);
        opts.tool.simplify(10);
      } else if (opts.tooltype == 'highligher') {
        this.addPoint(event.point);
        opts.tool.simplify(10);
      }

      if (opts.tooltype == 'circle' || opts.tooltype == 'rectangle') {
        this.addHistoryTool();
      }
    },

    addImg:function (img) {
      window.room.createTool(new opts.paper.Raster(img));
      opts.tool.position = opts.paper.view.center;

      this.addHistoryTool();
    },

    addPoint:function (point) {
      opts.tool.add(point);
    },

    clearCanvas:function () {
      $(opts.paper.project.activeLayer.children).each(function () {
        this.remove()
      });

      opts.historytool = []
      opts.selectedTool = null;
      opts.historyCounter = undefined;

      this.redraw();
    },

    removeSelected:function () {
      if (opts.selectedTool) {
        // add new 'remove' item into history and link it to removed item.
        window.room.addHistoryTool(opts.selectedTool, "remove");

        opts.selectedTool.opacity = 0;

        if (opts.selectedTool.selectionRect) {
          opts.selectedTool.selectionRect.remove();
        }

        opts.selectedTool = null;
      }
    },

    prevhistory:function () {
      if (opts.historyCounter == 0) {
        return;
      }

      $("#redoLink").removeClass("disabled");

      opts.historyCounter = opts.historyCounter - 1;
      var item = opts.historytools[opts.historyCounter];
      if (typeof(item) != 'undefined') {
        if (item.type == "remove") {
          window.room.helper.reverseOpacity(item.tool);
        } else {
          window.room.helper.reverseOpacity(item);
        }

        this.redraw();
      }

      if (opts.historyCounter == 0) {
        $("#undoLink").addClass("disabled");
      }
    },

    nexthistory:function () {
      if (opts.historyCounter == opts.historytools.length) {
        return;
      }

      $("#undoLink").removeClass("disabled");

      var item = opts.historytools[opts.historyCounter];
      if (typeof(item) != 'undefined') {
        if (item.type == "remove") {
          window.room.helper.reverseOpacity(item.tool);
        } else {
          window.room.helper.reverseOpacity(item);
        }

        opts.historyCounter = opts.historyCounter + 1;
        this.redraw();
      }

      if (opts.historyCounter == opts.historytools.length) {
        $("#redoLink").addClass("disabled");
      }
    },

    getHistoryTools:function () {
      var visibleHistoryTools = new Array();
      $(opts.historytools).each(function () {
        if (!this.type && this.opacity != 0) {
          visibleHistoryTools.push(this);
        }
      });
      return visibleHistoryTools;
    },

    addHistoryTool:function (tool, type) {
      var tool = tool ? tool : opts.tool;
      if (opts.historyCounter != opts.historytools.length) { // rewrite history
        opts.historytools = opts.historytools.slice(0, opts.historyCounter)
      }

      if (type) {
        opts.historytools.push({tool:tool, type:type});
      } else {
        opts.historytools.push(tool);
      }

      opts.historyCounter = opts.historytools.length;

      $("#undoLink").removeClass("disabled");
      $("#redoLink").addClass("disabled");
    },

    redraw:function () {
      opts.paper.view.draw()
    },

    initUploader:function () {
      var uploader = new qq.FileUploader({
        element:$('#file-uploader')[0],
        action:'/file/upload',
        title_uploader:'Upload',
        failed:'Failed',
        multiple:true,
        cancel:'Cancel',
        debug:false,
        params:{'entity':3},
        onSubmit:function (id, fileName) {
          $(uploader._listElement).css('dispaly', '');
        },
        onComplete:function (id, fileName, responseJSON) {
          $(uploader._listElement).css('dispaly', 'none');
          if (responseJSON.fileName) {
            var img = $("<img src=\"/public/images/avatar.png\" width='100' height='100'>");
            $('#curavatardiv').prepend(img);

            window.room.addImg(img[0]);
          }
        }
      });
    }
  };

  var helper = {

    createSelectionRectangle:function (selectedTool) {
      var bounds = selectedTool.bounds;
      var additionalBound = parseInt(selectedTool.strokeWidth / 2);

      var selectionRect = new Path.Rectangle(bounds.x - additionalBound, bounds.y - additionalBound,
        bounds.width + (additionalBound * 2), bounds.height + (additionalBound * 2));

      var selectRectWidth = 8;
      var selectRectHalfWidth = selectRectWidth / 2;
      var topLeftRect = new Path.Rectangle(bounds.x - additionalBound - selectRectHalfWidth,
        bounds.y - additionalBound - selectRectHalfWidth, selectRectWidth, selectRectWidth);
      var bottomRightRect = new Path.Rectangle(bounds.x + bounds.width + additionalBound - selectRectHalfWidth,
        bounds.y + bounds.height + additionalBound - selectRectHalfWidth, selectRectWidth, selectRectWidth);

      var removeButton = new Raster("removeButton");
      removeButton.position = new Point(selectionRect.bounds.x + selectionRect.bounds.width, selectionRect.bounds.y);

      var selectionRectGroup = new Group([selectionRect, topLeftRect, bottomRightRect, removeButton]);

      selectionRectGroup.theRect = selectionRect;
      selectionRectGroup.topLeftRect = topLeftRect;
      selectionRectGroup.bottomRightRect = bottomRightRect;
      selectionRectGroup.removeButton = removeButton;

      window.room.createTool(selectionRect, {color:"skyblue", width:1, opacity:1, dashArray:[3, 3]});
      window.room.createTool(topLeftRect, {color:"blue", width:1, opacity:1});
      window.room.createTool(bottomRightRect, {color:"blue", width:1, opacity:1});
      window.room.createTool(removeButton);

      return selectionRectGroup;
    },

    reverseOpacity:function (elem) {
      if (elem.opacity == 0) {
        elem.opacity = 1;
      } else {
        elem.opacity = 0;
      }
    }

  };

  window.room = room;
  window.room.helper = helper;
});

$(document).ready(function () {
  window.room.init($("#myCanvas"), {paper:paper});

  // disable canvas text selection for cursor change
  var canvas = $("#myCanvas")[0];
  canvas.onselectstart = function () {
    return false;
  };

  canvas.onmousedown = function () {
    return false;
  };
});

function onMouseDown(event) {
  window.room.onMouseDown($("#myCanvas"), event);
}

function onMouseDrag(event) {
  window.room.onMouseDrag($("#myCanvas"), event);
}

function onMouseUp(event) {
  window.room.onMouseUp($("#myCanvas"), event);
}

function onMouseMove(event) {
  window.room.onMouseMove($("#myCanvas"), event);
}
