$(function () {
  var opts = {};
  var savedOpts = new Array();

  var defaultOpts = {
    paper:undefined,
    tool:undefined,
    selectedTool:undefined,
    image:undefined,
    historytools:[],
    tooltype:'line',
    historyCounter:undefined,
    color:'#000',
    defaultWidth:3,
    currentScale:1,
    opacity:1
  };

  var room = {
    init:function (canvas, opt) {
      $.extend(opts, opt);
      $.extend(opts, defaultOpts);

      opts.canvas = canvas;

      savedOpts.push(opts);

      $("#toolSelect > li, #panTool, #selectTool").on("click", function () {
        window.room.setTooltype($(this).data("tooltype"));
      });

      $('.color').click(function () {
        $('.color').removeClass('activen');
        opts.color = $(this).attr('data-color');
        $(this).addClass('activen');
      });

      $(document).on("click", "#canvasSelectDiv a", function () {
        window.room.selectCanvas(this);

        return false;
      });

      window.room.helper.initUploader();

      return false;
    },

    // *** Mouse events handling ***

    onMouseMove:function (canvas, event) {
      event.point = event.point.transform(new Matrix(1 / opts.currentScale, 0, 0, 1 / opts.currentScale, 0, 0));

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
      event.point = event.point.transform(new Matrix(1 / opts.currentScale, 0, 0, 1 / opts.currentScale, 0, 0));

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
      } else if (opts.tooltype == 'arrow') {
        var arrow = new opts.paper.Path();
        arrow.arrow = arrow;
        this.createTool(arrow);
        if (opts.tool.segments.length == 0) {
          opts.tool.add(event.point);
        }
        opts.tool.add(event.point);
        opts.tool.lineStart = event.point
      } else if (opts.tooltype == "select") {
        window.room.testSelect(event.point);
        window.room.drawSelectRect(event.point);
      } else if (opts.tooltype == "comment") {
        window.room.createComment();
      }

      /* this should be */
      if (opts.tooltype == 'line' || opts.tooltype == 'highligher') {
        this.addHistoryTool();
      }
    },

    onMouseDrag:function (canvas, event) {
      opts.dragPerformed = true;

      event.point = event.point.transform(new Matrix(1 / opts.currentScale, 0, 0, 1 / opts.currentScale, 0, 0));

      if (opts.tooltype == 'line') {
        opts.tool.add(event.point);
        opts.tool.smooth();
      } else if (opts.tooltype == 'highligher') {
        opts.tool.add(event.point);
        opts.tool.smooth();
      } else if (opts.tooltype == 'circle') {
        var sizes = event.downPoint - event.point;
        var rectangle = new opts.paper.Rectangle(event.point.x, event.point.y, sizes.x, sizes.y);
        this.createTool(new Path.Oval(rectangle));
        opts.tool.removeOnDrag();
      } else if (opts.tooltype == 'rectangle') {
        var sizes = event.downPoint - event.point;
        var rectangle = new opts.paper.Rectangle(event.point.x, event.point.y, sizes.x, sizes.y);
        this.createTool(new opts.paper.Path.Rectangle(rectangle));
        opts.tool.removeOnDrag();
      } else if (opts.tooltype == 'straightline') {
        opts.tool.lastSegment.point = event.point;
      } else if (opts.tooltype == 'arrow') {
        var arrow = opts.tool.arrow;
        arrow.lastSegment.point = event.point;

        var vector = event.point - arrow.lineStart;
        vector = vector.normalize(10);
        var triangle = new opts.paper.Path([
          event.point + vector.rotate(135),
          event.point,
          event.point + vector.rotate(-135)
        ]);
        this.createTool(triangle);

        var arrowGroup = new Group([triangle, arrow]);
        arrowGroup.arrow = arrow;
        opts.tool = arrowGroup;

        triangle.removeOnDrag();
      } else if (opts.tooltype == 'pan') {
        $(opts.paper.project.activeLayer.children).each(function () {
          if (this.translate) {
            this.translate(event.delta);
          }
        })
      } else if (opts.tooltype == 'select') {
        if (opts.selectedTool) {
          if (opts.selectedTool.scalersSelected) {
            var tool = opts.selectedTool;
            var boundingBox = opts.selectedTool.selectionRect;

            // get scale percentages
            var h = tool.bounds.height;
            var w = opts.selectedTool.bounds.width;
            var sx = (w + 2 * event.delta.x) / w;
            var sy = (h + 2 * event.delta.y) / h;

            // scale tool & bounding box
            tool.scale(sx, sy);
            boundingBox.theRect.scale(sx, sy);

            var bx = boundingBox.theRect.bounds.x;
            var by = boundingBox.theRect.bounds.y;
            var bw = boundingBox.theRect.bounds.width;
            var bh = boundingBox.theRect.bounds.height;

            // move bounding box controls
            boundingBox.topLeftRect.position = new Point(bx + bw, by + bh);
            boundingBox.bottomRightRect.position = new Point(bx, by);
            boundingBox.removeButton.position = new Point(bx + bw, by);
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
      event.point = event.point.transform(new Matrix(1 / opts.currentScale, 0, 0, 1 / opts.currentScale, 0, 0));

      if (opts.tooltype == 'line') {
        opts.tool.add(event.point);
        opts.tool.simplify(10);
      } else if (opts.tooltype == 'highligher') {
        opts.tool.add(event.point);
        opts.tool.simplify(10);
      }

      if (opts.tooltype == 'straightline' || opts.tooltype == 'arrow' ||
        opts.tooltype == 'circle' || opts.tooltype == 'rectangle') {
        this.addHistoryTool();
      }

      opts.dragPerformed = false;
    },

    // *** Image upload & canvas manipulation ***

    handleUpload:function (image) {
      if (opts.image) {
        this.addNewCanvas();
      }

      this.addImage(image);
    },

    addImage:function (image) {
      var img = new opts.paper.Raster(image);
      opts.paper.project.activeLayer.insertChild(0, img);

      img.size.width = image.width;
      img.size.height = image.height;
      img.position = opts.paper.view.center;

      opts.image = image;
    },

    addNewCanvas:function () {
      this.eraseCanvas();

      var oldOpts = opts;
      opts = {};
      $.extend(opts, defaultOpts);

      opts.paper = oldOpts.paper;
      savedOpts.push(opts);

      $("#canvasSelectDiv a").removeClass("canvasSelected");
      $("#canvasSelectDiv").append("<a href='#' class='canvasSelected'></a>")
    },

    selectCanvas:function (anchor) {
      if ($(anchor).hasClass("canvasSelected")) {
        return;
      }

      $("#canvasSelectDiv a").removeClass("canvasSelected");

      var index = $(anchor).index();
      var canvasOpts = this.findCanvasOptsByIndex(index);
      if (!canvasOpts) {
        alert("No canvas opts by given index=" + index);
      }

      this.eraseCanvas();
      opts = canvasOpts;

      window.room.addImage(opts.image);
      this.restoreFromHistory(opts.historytools);

      $(anchor).addClass("canvasSelected");
    },

    findCanvasOptsByIndex:function (index) {
      var canvasOpts;
      $(savedOpts).each(function (indexInternal) {
        if (indexInternal == index) {
          canvasOpts = this;
        }
      });
      return canvasOpts;
    },

    clearCanvas:function () {
      window.room.helper.setOpacityElems(opts.historytools, 0);
      window.room.addHistoryTool(null, "clear");
      this.unselect();

      this.redraw();
    },

    eraseCanvas:function () {
      $(opts.paper.project.activeLayer.children).each(function () {
        this.remove();
      });
    },

    setCanvasScale:function (scale) {
      var finalScale = scale / opts.currentScale;
      opts.currentScale = scale;

      var transformMatrix = new Matrix(finalScale, 0, 0, finalScale, 0, 0);
      opts.paper.project.activeLayer.transform(transformMatrix);

      this.redraw();
    },

    addCanvasScale:function () {
      var scale = opts.currentScale + 0.1;
      this.setCanvasScale(scale);
    },

    subtractCanvasScale:function () {
      var scale = opts.currentScale - 0.1;
      this.setCanvasScale(scale);
    },

    // *** Save & restore state ***

    restoreState:function (state) {
      this.eraseCanvas();

      $(state).each(function () {
        var path = new opts.paper.Path();
        $(this.segments).each(function () {
          path.addSegment(createSegment(this.x, this.y, this.ix, this.iy, this.ox, this.oy));
        });
        path.closed = this.closed;

        window.room.createTool(path);
      });

      function createSegment(x, y, ix, iy, ox, oy) {
        var handleIn = new Point(ix, iy);
        var handleOut = new Point(ox, oy);
        var firstPoint = new Point(x, y);

        return new opts.paper.Segment(firstPoint, handleIn, handleOut);
      }
    },

    saveState:function () {
      var elements = [];
      $(paper.project.activeLayer.children).each(function () {
        var element = {};
        element.segments = [];
        element.closed = this.closed;
        $(this.segments).each(function () {
          element.segments.push({
            x:this.point.x,
            y:this.point.y,
            ix:this.handleIn.x,
            iy:this.handleIn.y,
            ox:this.handleOut.x,
            oy:this.handleOut.y
          });
        });
        elements.push(element);
      });

      return elements;
    },

    // *** Item manipulation ***

    createTool:function (tool, settings) {
      if (!settings) {
        settings = {};
      }

      opts.tool = tool;
      opts.tool.strokeColor = settings.color ? settings.color : opts.color;
      opts.tool.strokeWidth = settings.width ? settings.width : opts.defaultWidth;
      opts.tool.opacity = settings.opacity ? settings.opacity : opts.opacity;
      opts.tool.dashArray = settings.dashArray ? settings.dashArray : undefined;
    },

    setTooltype:function (tooltype) {
      opts.tooltype = tooltype;
    },

    createComment:function () {
      console.log(opts.canvas);
      $(opts.canvas).append("<div>The div</div>");
    },

    removeSelected:function () {
      if (opts.selectedTool) {
        // add new 'remove' item into history and link it to removed item.
        window.room.addHistoryTool(opts.selectedTool, "remove");
        opts.selectedTool.opacity = 0;

        this.unselect();

        this.redraw();
      }
    },

    unselect:function () {
      if (opts.selectedTool.selectionRect) {
        opts.selectedTool.selectionRect.remove();
      }
      opts.selectedTool = null;
    },

    testSelect:function (point) {
      var selectTimeDelta = opts.selectTime ? new Date().getTime() - opts.selectTime : undefined;
      opts.selectTime = new Date().getTime();

      var selected = false;

      // Select scalers or remove buttton has highest priority.
      if (opts.selectedTool && opts.selectedTool.selectionRect &&
        (opts.selectedTool.selectionRect.topLeftRect.bounds.contains(point) ||
          opts.selectedTool.selectionRect.bottomRightRect.bounds.contains(point) ||
          opts.selectedTool.selectionRect.removeButton.bounds.contains(point))) {
        selected = true;
      }

      // Already selected item has next highest priority if time between selectes was big.
      if (selectTimeDelta > 750 && opts.selectedTool && opts.selectedTool.selectionRect &&
        opts.selectedTool.selectionRect.bounds.contains(point)) {
        selected = true;
      }

      if (!selected) {
        var previousSelectedTool = opts.selectedTool;
        $(window.room.getHistoryTools()).each(function () {
          if (this.bounds.contains(point)) {
            opts.selectedTool = this;
            selected = true;
          }

          if (selectTimeDelta < 750) {
            if (opts.selectedTool && previousSelectedTool) {
              return opts.selectedTool.id == previousSelectedTool.id;
            }
          }
        });
      }

      if (!selected) {
        opts.selectedTool = null;
      }
    },

    drawSelectRect:function (point) {
      if (opts.selectedTool) {
        opts.selectedTool.selectionRect = window.room.helper.createSelectionRectangle(opts.selectedTool);
        $("#removeSelected").removeClass("disabled");

        if (opts.selectedTool.selectionRect.topLeftRect.bounds.contains(point)) {
          opts.selectedTool.scalersSelected = "topLeft"
        } else if (opts.selectedTool.selectionRect.bottomRightRect.bounds.contains(point)) {
          opts.selectedTool.scalersSelected = "bottomRight"
        } else {
          opts.selectedTool.scalersSelected = false;
        }

        if (opts.selectedTool.selectionRect.removeButton.bounds.contains(point)) {
          window.room.removeSelected();
        }
      }
    },

    // *** History, undo & redo ***

    prevhistory:function () {
      if (opts.historyCounter == 0) {
        return;
      }

      $("#redoLink").removeClass("disabled");

      opts.historyCounter = opts.historyCounter - 1;
      var item = opts.historytools[opts.historyCounter];
      if (typeof(item) != 'undefined') {
        executePrevHistory(item);
        this.redraw();
      }

      if (opts.historyCounter == 0) {
        $("#undoLink").addClass("disabled");
      }

      function executePrevHistory(item) {
        if (item.type == "remove") {
          window.room.helper.reverseOpacity(item.tool);
        } else if (item.type == "clear") {
          window.room.helper.setOpacityElems(opts.historytools, 1);
        } else {
          window.room.helper.reverseOpacity(item);
        }
      }
    },

    nexthistory:function () {
      if (opts.historyCounter == opts.historytools.length) {
        return;
      }

      $("#undoLink").removeClass("disabled");

      var item = opts.historytools[opts.historyCounter];
      if (typeof(item) != 'undefined') {
        executeNextHistory(item);

        opts.historyCounter = opts.historyCounter + 1;
        this.redraw();
      }

      if (opts.historyCounter == opts.historytools.length) {
        $("#redoLink").addClass("disabled");
      }

      function executeNextHistory(item) {
        if (item.type == "remove") {
          window.room.helper.reverseOpacity(item.tool);
        } else if (item.type == "clear") {
          window.room.helper.setOpacityElems(opts.historytools, 0);
        } else {
          window.room.helper.reverseOpacity(item);
        }
      }
    },

    restoreFromHistory:function (history) {
      $(history).each(function () {
        if (!this.type) {
          opts.paper.project.activeLayer.addChild(this);
        }
      });
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

      if (type == "remove") {
        opts.historytools.push({tool:tool, type:type});
      } else if (type == "clear") {
        opts.historytools.push({type:type});
      } else {
        opts.historytools.push(tool);
      }

      opts.historyCounter = opts.historytools.length;

      $("#undoLink").removeClass("disabled");
      $("#redoLink").addClass("disabled");
    },

    // *** Misc methods ***

    redraw:function () {
      opts.paper.view.draw()
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

      var removeButton = new Raster(removeImg);
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
    },

    setOpacityElems:function (elems, opacity) {
      $(elems).each(function () {
        if (this.type == "remove") {
          this.tool.opacity = 0;
        } else if (!this.type) {
          this.opacity = opacity;
        }
      });
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
          $(uploader._listElement).css('dispaly', 'none');
        },
        onComplete:function (id, fileName, responseJSON) {
          $(uploader._listElement).css('dispaly', 'none');
          if (responseJSON.fileName) {
            var image = new Image();
            image.src = "/public/images/avatar.png";
            $(image).on("load", function () {
              window.room.handleUpload(image);
            })
          }
        }
      });
    }

  };

  window.room = room;
  window.room.helper = helper;

  var removeImg = new Image();
  removeImg.src = "/images/remove.png";
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
