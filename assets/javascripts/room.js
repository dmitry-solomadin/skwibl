$(function () {
  var opts = {
    paper:undefined,
    project:undefined,
    tool:undefined,
    selectedTool:undefined,
    historytools:[],
    tooltype:'line',
    historyCounter:undefined,
    color:'#000',
    strokeWidth:5,
    opacity:1,
    imgid:'',
    createimg:0
  };

  var room = {
    init:function (canvas, opt) {
      var options = $.extend({}, opts, opt);
      opts = options;
      this.createTool(new opts.paper.Path());
      opts.canvas = canvas;

      $("#toolSelect > li, #panTool, #selectTool").on("click", function () {
        window.room.setTooltype($(this).data("tooltype"));
      });

      $('.color').click(function () {
        $('.color').removeClass('activen');
        opts.color = $(this).attr('data-color');
        $(this).addClass('activen');
      });

      $("#slider2").slider({
        min:1,
        max:100,
        value:1,
        change:function (event, ui) {
          opts.strokeWidth = ui.value;
        },
        stop:function (event, ui) {
          opts.strokeWidth = ui.value;
        }
      });

      this.initUploader();

      return false;
    },

    createTool:function (tool) {
      opts.tool = tool;
      this.setStrokeColor();
      this.setStrokeWidth();
      this.setOpacity();
    },

    setTooltype:function (tooltype) {
      opts.tooltype = tooltype;
    },

    setStrokeColor:function () {
      opts.tool.strokeColor = opts.color;
    },

    setStrokeWidth:function (strokeWidth) {
      if (typeof(strokeWidth) != 'undefined') {
        opts.strokeWidth = strokeWidth;
      }
      opts.tool.strokeWidth = opts.strokeWidth;
    },

    setOpacity:function (opacity) {
      if (typeof(opacity) != 'undefined') {
        opts.opacity = opacity;
      }
      opts.tool.opacity = opts.opacity;
    },

    onMouseDown:function (canvas, event) {
      opts.strokeWidth = 5;
      opts.opacity = 1;
      if (opts.tooltype == 'line') {
        this.createTool(new opts.paper.Path());
      } else if (opts.tooltype == 'highligher') {
        opts.strokeWidth = 15;
        opts.opacity = 0.7;
        this.createTool(new opts.paper.Path());
      } else if (opts.tooltype == 'straightline') {
        this.createTool(new opts.paper.Path());
        if (opts.tool.segments.length == 0) {
          opts.tool.add(event.point);
        }
        opts.tool.add(event.point);
      } else if (opts.tooltype == 'img') {
        if (opts.createimg == 0) {
          this.createTool(new opts.paper.Raster(opts.imgid));
          opts.tool.position = event.point;
          opts.createimg = 1;
        } else {
          if (opts.tool.hitTest(event.point)) {
            opts.createimg = 0;
          }
        }
      } else if (opts.tooltype == 'pan') {
        var selectedSomething = false;
        $(opts.historytools).each(function () {
          if (this.bounds.contains(event.point)) {
            opts.selectedTool = this;
            opts.selectedTool.selectedPoint = event.point
            selectedSomething = true;
          }
        })

        if (!selectedSomething) {
          opts.selectedTool = null;
        }
      }

      if (opts.tooltype == 'line' || opts.tooltype == 'circle' ||
        opts.tooltype == 'rectangle' || opts.tooltype == 'straightline' ||
        opts.tooltype == 'highligher') {
        this.addHistoryTool();
      }
    },

    onMouseDrag:function (canvas, event) {
      if (opts.tooltype == 'line') {
        this.addPoint(event.point);
      } else if (opts.tooltype == 'highligher') {
        this.addPoint(event.point);
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
        if (opts.selectedTool) {
          opts.selectedTool.translate(event.point - opts.selectedTool.selectedPoint);
          opts.selectedTool.selectedPoint = event.point
        }
      }
    },

    onMouseUp:function (canvas, event) {
      if (opts.tooltype == 'line') {
        this.addPoint(event.point);
      } else if (opts.tooltype == 'highligher') {
        this.addPoint(event.point);
      }
    },

    addImg:function (img) {
      window.room.createTool(new opts.paper.Raster(img));
      opts.tool.position = opts.paper.view.center;
      console.log(opts.tool.width);

      this.addHistoryTool();
    },

    addPoint:function (point) {
      opts.tool.add(point);
    },

    clearCanvas:function () {
      $(opts.paper.project.activeLayer.children).each(function () {
        this.remove()
      });

      this.redraw();
    },

    prevhistory:function () {
      if (opts.historyCounter == 0) {
        return;
      }

      $("#redoLink").removeClass("disabled");

      opts.historyCounter = opts.historyCounter - 1;
      if (typeof(opts.historytools[opts.historyCounter]) != 'undefined') {
        opts.historytools[opts.historyCounter].opacity = 0;
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

      if (typeof(opts.historytools[opts.historyCounter]) != 'undefined') {
        opts.historytools[opts.historyCounter].opacity = 1;
        opts.historyCounter = opts.historyCounter + 1;
        this.redraw();
      }

      if (opts.historyCounter == opts.historytools.length) {
        $("#redoLink").addClass("disabled");
      }
    },

    addHistoryTool:function () {
      if (opts.historyCounter != opts.historytools.length) { // rewrite history
        opts.historytools = opts.historytools.slice(0, opts.historyCounter)
      }

      opts.historytools.push(opts.tool);
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

  window.room = room
});

$(document).ready(function () {
  window.room.init($("#myCanvas"), {paper:paper});
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
