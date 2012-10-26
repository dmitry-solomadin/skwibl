$(function () {
  var nextId = 1;
  var opts = {};
  var savedOpts = new Array();

  var COMMENT_RECTANGLE_ROUNDNESS = 8;
  var COMMENT_STYLE = {width:"2", color:"#C2E1F5"};

  var defaultOpts = {
    tooltype:'line',
    color:'#404040',
    defaultWidth:2,
    currentScale:1,
    opacity:1
  };

  var room = {
    init:function (opt) {
      $.extend(opts, opt);
      room.initOpts(opts);

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
      window.room.helper.initHotkeys();

      // disable canvas text selection for cursor change
      var canvas = $("#myCanvas")[0];
      canvas.onselectstart = function () {
        return false;
      };

      canvas.onmousedown = function () {
        return false;
      };

      return false;
    },

    // *** Mouse events handling ***

    onMouseMove:function (canvas, event) {
      event.point = event.point.transform(new Matrix(1 / opts.currentScale, 0, 0, 1 / opts.currentScale, 0, 0));

      $(canvas).css({cursor:"default"});

      if (opts.selectedTool && opts.selectedTool.selectionRect) {
        if (opts.selectedTool.selectionRect.bottomRightScaler.bounds.contains(event.point)) {
          $(canvas).css({cursor:"se-resize"});
        } else if (opts.selectedTool.selectionRect.topLeftScaler.bounds.contains(event.point)) {
          $(canvas).css({cursor:"nw-resize"});
        } else if (opts.selectedTool.selectionRect.topRightScaler.bounds.contains(event.point)) {
          $(canvas).css({cursor:"ne-resize"});
        } else if (opts.selectedTool.selectionRect.bottomLeftScaler.bounds.contains(event.point)) {
          $(canvas).css({cursor:"sw-resize"});
        } else if (opts.selectedTool.selectionRect.removeButton &&
          opts.selectedTool.selectionRect.removeButton.bounds.contains(event.point)) {
          $(canvas).css({cursor:"pointer"});
        }
      }
    },

    initOpts:function (opts) {
      $.extend(opts, defaultOpts);
      opts.historytools = {
        eligibleHistory:[],
        allHistory:[]
      };
    },

    onMouseDown:function (canvas, event) {
      event.point = event.point.transform(new Matrix(1 / opts.currentScale, 0, 0, 1 / opts.currentScale, 0, 0));

      $("#removeSelected").addClass("disabled");
      if (opts.selectedTool && opts.selectedTool.selectionRect) {
        opts.selectedTool.selectionRect.remove();
      }

      opts.commentRect = null;

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
      }

      /* this should be here because sometimes mouse up event won't fire. */
      if (opts.tooltype == 'line' || opts.tooltype == 'highligher') {
        opts.tool.eligible = true;
        this.addHistoryTool();
      }
    },

    onMouseDrag:function (canvas, event) {
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
      } else if (opts.tooltype == 'comment') {
        var sizes = event.downPoint - event.point;

        if (sizes.x < 0 && sizes.y < 0) {
          var x = event.downPoint.x, y = event.downPoint.y, w = Math.abs(sizes.x), h = Math.abs(sizes.y);
        } else {
          x = event.point.x, y = event.point.y, w = sizes.x, h = sizes.y;
        }

        var rectangle = new Path.RoundRectangle(x, y, w, h, COMMENT_RECTANGLE_ROUNDNESS, COMMENT_RECTANGLE_ROUNDNESS);
        opts.commentRect = rectangle;
        this.createTool(rectangle, COMMENT_STYLE);
        opts.tool.removeOnDrag();
      } else if (opts.tooltype == 'straightline') {
        opts.tool.lastSegment.point = event.point;
      } else if (opts.tooltype == 'arrow') {
        var arrow = opts.tool.arrow;
        arrow.lastSegment.point = event.point;

        var arrowGroup = new Group([arrow]);
        arrowGroup.arrow = arrow;
        arrowGroup.drawTriangle = function () {
          var vector = this.arrow.lastSegment.point - this.arrow.segments[0].point;
          vector = vector.normalize(10);
          if (this.triangle) {
            this.triangle.segments[0].point = this.arrow.lastSegment.point + vector.rotate(135);
            this.triangle.segments[1].point = this.arrow.lastSegment.point;
            this.triangle.segments[2].point = this.arrow.lastSegment.point + vector.rotate(-135);
          } else {
            var triangle = new opts.paper.Path([
              this.arrow.lastSegment.point + vector.rotate(135),
              this.arrow.lastSegment.point,
              this.arrow.lastSegment.point + vector.rotate(-135)
            ]);
            this.triangle = triangle;
            this.addChild(triangle);
          }

          return this.triangle;
        };

        var triangle = arrowGroup.drawTriangle();
        this.createTool(triangle);

        opts.tool = arrowGroup;

        triangle.removeOnDrag();
      } else if (opts.tooltype == 'pan') {
        $(opts.historytools.allHistory).each(function () {
          if (this.commentMin) {
            var commentRect = this.type != "comment";

            var dx = opts.currentScale * event.delta.x;
            var dy = opts.currentScale * event.delta.y;

            this.commentMin.css({top:this.commentMin.position().top + dy,
              left:this.commentMin.position().left + dx});
            this.commentMin[0].arrow.translate(event.delta);
            this.commentMin[0].$maximized.css({top:this.commentMin[0].$maximized.position().top + dy,
              left:this.commentMin[0].$maximized.position().left + dx});
            if (commentRect) {
              this.translate(event.delta);
            }
          } else if (!this.type && this.translate) {
            this.translate(event.delta);
          }
        })
      } else if (opts.tooltype == 'select') {
        if (opts.selectedTool) {
          if (opts.selectedTool.scalersSelected) {
            var tool = opts.selectedTool;

            var scaleZone = window.room.helper.getReflectZone(tool, event.point.x, event.point.y);
            if (scaleZone) {
              tool.scaleZone = scaleZone;
            } else {
              scaleZone = tool.scaleZone;
            }

            var zx = scaleZone.zx, zy = scaleZone.zy;
            var scalePoint = scaleZone.point;

            var dx = event.delta.x;
            var dy = event.delta.y;

            var scaleFactors = window.room.helper.getScaleFactors(tool, zx, zy, dx, dy);
            var sx = scaleFactors.sx, sy = scaleFactors.sy;

            // scale tool
            this.doScale(tool, sx, sy, scalePoint);

            tool.selectionRect.remove();
            tool.selectionRect = window.room.helper.createSelectionRectangle(tool);
          } else {
            window.room.translateSelected(event.delta);
          }

          // redraw comment arrow if there is one.
          if (opts.selectedTool.commentMin) {
            commentsHelper.redrawArrow(opts.selectedTool.commentMin);
          }
        }
      }
    },

    doScale:function (tool, sx, sy, scalePoint) {
      var transformMatrix = new Matrix().scale(sx, sy, scalePoint);
      if (transformMatrix._d == 0 || transformMatrix._a == 0) {
        return;
      }

      if (tool.tooltype == "arrow") {
        tool.arrow.scale(sx, sy, scalePoint);
        tool.drawTriangle();
      } else {
        tool.transform(transformMatrix);
      }

      tool.selectionRect.theRect.transform(transformMatrix);
    },

    onMouseUp:function (canvas, event) {
      event.point = event.point.transform(new Matrix(1 / opts.currentScale, 0, 0, 1 / opts.currentScale, 0, 0));

      if (opts.tooltype == 'line') {
        opts.tool.add(event.point);
        opts.tool.simplify(10);
      } else if (opts.tooltype == 'highligher') {
        opts.tool.add(event.point);
        opts.tool.simplify(10);
      } else if (opts.tooltype == "comment") {
        var commentMin = window.room.createComment(event.point.x, event.point.y, opts.commentRect);

        if (opts.commentRect) {
          opts.commentRect.commentMin = commentMin;
        }
      }

      if (opts.tool) {
        opts.tool.tooltype = opts.tooltype;
      }

      if (opts.tooltype == 'straightline' || opts.tooltype == 'arrow' ||
        opts.tooltype == 'circle' || opts.tooltype == 'rectangle') {
        opts.tool.eligible = true;
        this.addHistoryTool();
      }

      if (opts.tooltype == 'comment') {
        if (opts.commentRect) {
          opts.tool.eligible = true;
          this.addHistoryTool();
        } else {
          this.addHistoryTool({type:"comment", commentMin:commentMin, eligible:true});
        }
      }

      if (opts.tooltype == 'straightline' || opts.tooltype == 'arrow' ||
        opts.tooltype == 'circle' || opts.tooltype == 'rectangle' ||
        opts.tooltype == 'line' || opts.tooltype == 'highligher') {
        opts.tool.elementId = this.getNextIdAndIncrement();
        canvasIO.emit("elementUpdate", this.prepareElementToSend(opts.tool));
        canvasIO.emit("nextId");
      } else if (opts.tooltype == "comment") {
        commentMin.elementId = this.getNextIdAndIncrement();
        canvasIO.emit("commentUpdate", this.prepareCommentToSend(commentMin));
        canvasIO.emit("nextId");
      } else if (opts.tooltype == 'select' && opts.selectedTool) {
        canvasIO.emit("elementUpdate", this.prepareElementToSend(opts.selectedTool));
      }

      if (opts.tooltype == 'comment') {
        window.room.setTooltype("select");
      }

      this.updateSelectedCanvasThumb();
    },

    getNextIdAndIncrement:function () {
      var prevId = nextId;
      nextId = nextId + 1;
      return prevId;
    },

    // *** Image upload & canvas manipulation ***

    handleUpload:function (image) {
      if (opts.image) {
        this.addNewCanvas();
      }

      this.addImage(image);

      this.updateSelectedCanvasThumb();
    },

    addImage:function (image) {
      var img = new opts.paper.Raster(image);
      img.isImage = true;
      opts.paper.project.activeLayer.insertChild(0, img);

      img.size.width = image.width;
      img.size.height = image.height;
      img.position = opts.paper.view.center;

      opts.image = image;

      this.addHistoryTool(img);
    },

    clearCanvas:function () {
      window.room.addHistoryTool({
        type:"clear", tools:this.getSelectableTools(), eligible:true
      });
      $(opts.historytools.allHistory).each(function () {
        if (!this.type) {
          this.opacity = 0;
        }

        if (this.commentMin) {
          commentsHelper.hideComment(this.commentMin);
        }
      });

      this.unselect();
      this.redrawWithThumb();

      canvasIO.emit("eraseCanvas");
    },

    eraseCanvas:function () {
      $(opts.historytools.allHistory).each(function () {
        if (!this.type) {
          this.remove();
        }

        if (this.commentMin) {
          commentsHelper.hideComment(this.commentMin);
        }
      });

      room.redraw();
    },

    restoreCanvas:function () {
      $(opts.historytools.allHistory).each(function () {
        if (!this.type) {
          opts.paper.project.activeLayer.addChild(this);
        }

        if (this.commentMin) {
          commentsHelper.showComment(this.commentMin);
        }
      });
    },

    setCanvasScale:function (scale) {
      var finalScale = scale / opts.currentScale;
      opts.currentScale = scale;

      var transformMatrix = new Matrix(finalScale, 0, 0, finalScale, 0, 0);

      opts.paper.project.activeLayer.transform(transformMatrix);

      $(opts.historytools.allHistory).each(function () {
        if (this.commentMin) {
          this.commentMin.css({top:this.commentMin.position().top * finalScale,
            left:this.commentMin.position().left * finalScale});

          var commentMax = this.commentMin[0].$maximized;
          commentMax.css({top:commentMax.position().top * finalScale, left:commentMax.position().left * finalScale});

          commentsHelper.redrawArrow(this.commentMin);
        }
      });

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

    // *** Canvas thumbnails ***

    addNewCanvas:function () {
      this.eraseCanvas();

      var oldOpts = opts;
      opts = {};
      room.initOpts(opts);

      opts.paper = oldOpts.paper;
      savedOpts.push(opts);

      $("#canvasSelectDiv a").removeClass("canvasSelected");
      $("#canvasSelectDiv").append("<a href='#' class='canvasSelected'><canvas width='80' height='60'></canvas></a>")
    },

    updateSelectedCanvasThumb:function () {
      var selectedCanvas = $(".canvasSelected canvas");
      var selectedContext = selectedCanvas[0].getContext('2d');
      var canvas = opts.paper.project.view.element;
      var cvw = $(canvas).width(), cvh = $(canvas).height();
      var scw = $(selectedCanvas).width(), sch = $(selectedCanvas).height();
      var sy = sch / cvh;

      var transformMatrix = new Matrix(sy / opts.currentScale, 0, 0, sy / opts.currentScale, 0, 0);
      opts.paper.project.activeLayer.transform(transformMatrix);
      this.redraw();

      var shift = -((sy * cvw) - scw) / 2;

      selectedContext.clearRect(0, 0, scw, sch);
      for (var i = 0; i < 5; i++) {
        selectedContext.drawImage(canvas, shift, 0);
      }

      transformMatrix = new Matrix(opts.currentScale / sy, 0, 0, opts.currentScale / sy, 0, 0);
      opts.paper.project.activeLayer.transform(transformMatrix);
      this.redraw();
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

      room.eraseCanvas();
      opts = canvasOpts;
      room.restoreCanvas();

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

    // *** SOCKETS ***

    addOrUpdateCommentText:function (data) {
      var foundComment = helper.findByElementId(data.elementId);
      commentsHelper.addCommentText(foundComment.commentMin, data.text, false);
    },

    addOrUpdateComment:function (data, initial) {
      if (initial) {
        $(data).each(function () {
          createNewComment(this);
        })
      } else {
        var foundComment = helper.findByElementId(data.elementId);
        if (foundComment) {
          updateComment(foundComment, data)
        } else {
          createNewComment(data);
        }
      }

      window.room.redrawWithThumb();

      function createNewComment(comment) {
        var rect = null;
        if (comment.rect) {
          var rect = new Path.RoundRectangle(comment.rect.x, comment.rect.y, comment.rect.w, comment.rect.h,
            COMMENT_RECTANGLE_ROUNDNESS, COMMENT_RECTANGLE_ROUNDNESS);
          window.room.createTool(rect, COMMENT_STYLE);
        }

        var commentMin = window.room.createComment(comment.min.x, comment.min.y, rect, comment.max);
        commentMin.elementId = comment.elementId;

        if (rect) {
          rect.commentMin = commentMin;
          rect.eligible = false;
          window.room.addHistoryTool(rect);
        } else {
          window.room.addHistoryTool({type:"comment", commentMin:commentMin, eligible:false});
        }
      }

      function updateComment(comment, updatedComment) {
        comment.commentMin.css({left:updatedComment.min.x, top:updatedComment.min.y});
        comment.commentMin[0].$maximized.css({left:updatedComment.max.x, top:updatedComment.max.y});
        commentsHelper.redrawArrow(comment.commentMin);
      }
    },

    socketRemoveElement:function (data) {
      helper.findByElementId(data).remove();

      this.unselectIfSelected(data);
      this.redrawWithThumb();
    },

    socketRemoveComment:function (data) {
      var element = helper.findByElementId(data);

      var commentMin = element.commentMin;
      commentMin[0].$maximized.remove();
      commentMin[0].arrow.remove();
      if (commentMin[0].rect) {
        commentMin[0].rect.remove();
      }
      commentMin.remove();

      this.unselectIfSelected(data);
      this.redrawWithThumb();
    },

    addOrUpdateElement:function (data, initial) {
      if (initial) {
        $(data).each(function () {
          createNewElement(this);
        })
      } else {
        var foundPath = helper.findByElementId(data.elementId);
        if (foundPath) {
          this.unselectIfSelected(foundPath.elementId);
          foundPath.removeSegments();
          $(data.segments).each(function () {
            foundPath.addSegment(createSegment(this.x, this.y, this.ix, this.iy, this.ox, this.oy));
          });

          if (foundPath.commentMin) {
            commentsHelper.redrawArrow(foundPath.commentMin);
          }
        } else {
          createNewElement(data);
        }
      }

      window.room.redrawWithThumb();

      function createSegment(x, y, ix, iy, ox, oy) {
        var handleIn = new Point(ix, iy);
        var handleOut = new Point(ox, oy);
        var firstPoint = new Point(x, y);

        return new opts.paper.Segment(firstPoint, handleIn, handleOut);
      }

      function createNewElement(fromElement) {
        var path = new opts.paper.Path();
        $(fromElement.segments).each(function () {
          path.addSegment(createSegment(this.x, this.y, this.ix, this.iy, this.ox, this.oy));
        });
        path.closed = fromElement.closed;
        path.elementId = fromElement.elementId;

        window.room.createTool(path, {
          color:fromElement.strokeColor,
          width:fromElement.strokeWidth,
          opacity:fromElement.opacity
        });

        path.eligible = false;
        window.room.addHistoryTool(path);
      }
    },

    prepareCommentToSend:function (commentMin) {
      var comment = {
        min:{
          x:commentMin.position().left,
          y:commentMin.position().top
        },
        elementId:commentMin.elementId
      };

      var commentMax = commentMin[0].$maximized[0];
      if (commentMax) {
        comment.max = {
          x:$(commentMax).position().left,
          y:$(commentMax).position().top
        }
      }

      var commentRect = commentMin[0].rect;
      if (commentRect) {
        comment.rect = {
          x:commentRect.bounds.x,
          y:commentRect.bounds.y,
          w:commentRect.bounds.width,
          h:commentRect.bounds.height
        }
      }

      return comment;
    },

    prepareElementToSend:function (elementToSend) {
      var element = {};
      element.segments = [];
      element.elementId = elementToSend.elementId;
      element.closed = elementToSend.closed;
      element.strokeColor = elementToSend.strokeColor.toCssString();
      element.strokeWidth = elementToSend.strokeWidth;
      element.opacity = elementToSend.opacity;
      $(elementToSend.segments).each(function () {
        element.segments.push({
          x:this.point.x,
          y:this.point.y,
          ix:this.handleIn.x,
          iy:this.handleIn.y,
          ox:this.handleOut.x,
          oy:this.handleOut.y
        });
      });

      return element;
    },

    // *** Item manipulation ***

    createTool:function (tool, settings) {
      if (!settings) {
        settings = {};
      }

      if (!settings.justCreate) {
        opts.tool = tool;
      }

      opts.tool.strokeColor = settings.color ? settings.color : opts.color;
      opts.tool.strokeWidth = settings.width ? settings.width : opts.defaultWidth;
      if (settings.fillColor) {
        opts.tool.fillColor = settings.fillColor;
      }
      opts.tool.opacity = settings.opacity ? settings.opacity : opts.opacity;
      opts.tool.dashArray = settings.dashArray ? settings.dashArray : undefined;
    },

    setTooltype:function (tooltype) {
      opts.tooltype = tooltype;
    },

    removeSelected:function () {
      if (opts.selectedTool) {
        // add new 'remove' item into history and link it to removed item.
        window.room.addHistoryTool({type:"remove", tool:opts.selectedTool, eligible:true});
        opts.selectedTool.opacity = 0;

        canvasIO.emit("elementRemove", opts.selectedTool.elementId);

        this.unselect();
        this.redrawWithThumb();
      }
    },

    translateSelected:function (deltaPoint) {
      if (opts.selectedTool) {
        opts.selectedTool.translate(deltaPoint);

        if (opts.selectedTool.selectionRect) {
          opts.selectedTool.selectionRect.translate(deltaPoint)
        }

        window.room.redrawWithThumb();
      }
    },

    unselect:function () {
      if (opts.selectedTool && opts.selectedTool.selectionRect) {
        opts.selectedTool.selectionRect.remove();
      }
      opts.selectedTool = null;
    },

    unselectIfSelected:function (elementId) {
      if (opts.selectedTool && opts.selectedTool.selectionRect && opts.selectedTool.elementId == elementId) {
        opts.selectedTool.selectionRect.remove();
        opts.selectedTool = null;
      }
    },

    testSelect:function (point) {
      var selectTimeDelta = opts.selectTime ? new Date().getTime() - opts.selectTime : undefined;
      opts.selectTime = new Date().getTime();

      var selected = false;

      // Select scalers or remove buttton has highest priority.
      if (opts.selectedTool && opts.selectedTool.selectionRect &&
        (window.room.helper.elementInArrayContainsPoint(opts.selectedTool.selectionRect.scalers, point) ||
          (opts.selectedTool.selectionRect.removeButton &&
            opts.selectedTool.selectionRect.removeButton.bounds.contains(point)))) {
        selected = true;
      }

      // Already selected item has next highest priority if time between selectes was big.
      if (selectTimeDelta > 750 && opts.selectedTool && opts.selectedTool.selectionRect &&
        opts.selectedTool.selectionRect.bounds.contains(point)) {
        selected = true;
      }

      if (!selected) {
        var previousSelectedTool = opts.selectedTool;
        $(window.room.getSelectableTools()).each(function () {
          if (this.isImage || this.type) {
            return true; // uploaded image is not selectable.
          }

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
      var tool = opts.selectedTool;
      if (tool) {
        tool.selectionRect = window.room.helper.createSelectionRectangle(tool);
        $("#removeSelected").removeClass("disabled");

        if (tool.selectionRect.topLeftScaler.bounds.contains(point)) {
          tool.scalersSelected = true;
          tool.scaleZone = {
            point:new Point(tool.bounds.x + tool.bounds.width, tool.bounds.y + tool.bounds.height),
            zx:-1, zy:-1
          };
        } else if (tool.selectionRect.bottomRightScaler.bounds.contains(point)) {
          tool.scalersSelected = true;
          tool.scaleZone = {
            point:new Point(tool.bounds.x, tool.bounds.y),
            zx:1, zy:1
          };
        } else if (tool.selectionRect.topRightScaler.bounds.contains(point)) {
          tool.scalersSelected = true;
          tool.scaleZone = {
            point:new Point(tool.bounds.x, tool.bounds.y + tool.bounds.height),
            zx:1, zy:-1
          };
        } else if (tool.selectionRect.bottomLeftScaler.bounds.contains(point)) {
          tool.scalersSelected = true;
          tool.scaleZone = {
            point:new Point(tool.bounds.x + tool.bounds.width, tool.bounds.y),
            zx:-1, zy:1
          };
        } else {
          tool.scalersSelected = false;
        }

        if (tool.selectionRect.removeButton && tool.selectionRect.removeButton.bounds.contains(point)) {
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
      var item = opts.historytools.eligibleHistory[opts.historyCounter];
      if (typeof(item) != 'undefined') {
        executePrevHistory(item);
        this.redrawWithThumb();
      }

      if (opts.historyCounter == 0) {
        $("#undoLink").addClass("disabled");
      }

      function executePrevHistory(item, reverse) {
        if (item.type == "remove") {
          executePrevHistory(item.tool, true);
        } else if (item.type == "clear") {
          $(item.tools).each(function () {
            executePrevHistory(this, true);
          });
        } else if (item.commentMin) {
          if (reverse) {
            commentsHelper.showComment(item.commentMin);
          } else {
            commentsHelper.hideComment(item.commentMin);
          }
        } else {
          window.room.helper.reverseOpacity(item);
        }
      }
    },

    nexthistory:function () {
      if (opts.historyCounter == opts.historytools.eligibleHistory.length) {
        return;
      }

      $("#undoLink").removeClass("disabled");

      var item = opts.historytools.eligibleHistory[opts.historyCounter];
      if (typeof(item) != 'undefined') {
        executeNextHistory(item);

        opts.historyCounter = opts.historyCounter + 1;
        this.redrawWithThumb();
      }

      if (opts.historyCounter == opts.historytools.eligibleHistory.length) {
        $("#redoLink").addClass("disabled");
      }

      function executeNextHistory(item, reverse) {
        if (item.type == "remove") {
          executeNextHistory(item.tool, true);
        } else if (item.type == "clear") {
          $(item.tools).each(function () {
            executeNextHistory(this, true);
          });
        } else if (item.commentMin) {
          if (reverse) {
            commentsHelper.hideComment(item.commentMin);
          } else {
            commentsHelper.showComment(item.commentMin);
          }
        } else {
          window.room.helper.reverseOpacity(item);
        }
      }
    },

    getSelectableTools:function () {
      // get all tools that are visible and have special marker
      var selectableTools = new Array();
      $(opts.historytools.allHistory).each(function () {
        if (this.opacity != 0) {
          selectableTools.push(this);
        }
      });

      return selectableTools;
    },

    addHistoryTool:function (tool) {
      var tool = tool ? tool : opts.tool;
      if (opts.historyCounter != opts.historytools.eligibleHistory.length) { // rewrite history
        opts.historytools.eligibleHistory = opts.historytools.eligibleHistory.slice(0, opts.historyCounter)
      }

      if (tool.eligible) {
        opts.historytools.eligibleHistory.push(tool);
      }
      opts.historytools.allHistory.push(tool);

      opts.historyCounter = opts.historytools.eligibleHistory.length;

      if (tool.eligible) {
        $("#undoLink").removeClass("disabled");
        $("#redoLink").addClass("disabled");
      }
    },

    // *** Comments ***

    createComment:function (x, y, rect, max) {
      var COMMENT_SHIFT_X = 75;
      var COMMENT_SHIFT_Y = -135;

      if (y < 100) {
        COMMENT_SHIFT_X = 75;
        COMMENT_SHIFT_Y = 55;
      }

      var commentMin = $("<div class='comment-minimized" + (rect ? " hide" : "") + "'>&nbsp;</div>");
      commentMin.css({left:x, top:y});

      var commentMax = $("<div class='comment-maximized'></div>");
      var max_x = max ? max.x : x + COMMENT_SHIFT_X;
      var max_y = max ? max.y : y + COMMENT_SHIFT_Y;
      commentMax.css({left:max_x, top:max_y});
      var commentHeader = $("<div class='comment-header'>" +
        "<div class='fr'><span class='comment-minimize'></span><span class='comment-remove'></span></div>" +
        "</div>");

      commentHeader.find(".comment-minimize").on("click", function () {
        commentsHelper.foldComment(commentMin);
      });

      commentHeader.find(".comment-remove").on("click", function () {
        commentsHelper.removeComment(commentMin);
      });

      commentMin.on("mousedown", function () {
        commentsHelper.unfoldComment(commentMin);
      });

      commentMax.append(commentHeader);
      var commentContent = $("<div class='comment-content'>" +
        "<textarea class='comment-reply' placeholder='Type a comment...'></textarea>" +
        "<input type='button' class='btn fr comment-send hide' value='Send'>" +
        "</div>");
      commentMax.append(commentContent);

      commentHeader.drags({
        onDrag:function (dx, dy) {
          commentMax.css({left:(commentMax.position().left + dx) + "px", top:(commentMax.position().top + dy) + "px"});
          commentsHelper.redrawArrow(commentMin);
        },
        onAfterDrag:function () {
          canvasIO.emit("commentUpdate", window.room.prepareCommentToSend(commentMin));
        }
      });

      commentMin.drags({
        onDrag:function (dx, dy) {
          commentMin.css({left:(commentMin.position().left + dx) + "px", top:(commentMin.position().top + dy) + "px"});
          commentsHelper.redrawArrow(commentMin);
          canvasIO.emit("commentUpdate", window.room.prepareCommentToSend(commentMin));
        },
        onAfterDrag:function () {
          canvasIO.emit("commentUpdate", window.room.prepareCommentToSend(commentMin));
        }
      });

      $(document).on("click", function (evt) {
        $(".comment-send:visible").each(function () {
          $(this).hide();

          commentsHelper.redrawArrow(commentMin);
        });

        if (evt.target) {
          $(evt.target).parent(".comment-content").find(".comment-send").show();
        }
      });

      $(commentMax).find(".comment-send").on("click", function () {
        var commentTextarea = commentMax.find(".comment-reply");
        commentsHelper.addCommentText(commentMin, commentTextarea.val(), true);
        commentTextarea.val("");
      });

      commentMin[0].$maximized = commentMax;
      commentMin[0].rect = rect;

      $("#room-content").prepend(commentMin);
      $("#room-content").prepend(commentMax);

      var bp = commentsHelper.getArrowBindPoint(commentMin, commentMax.position().left + (commentMax.width() / 2),
        commentMax.position().top + (commentMax.height() / 2));
      var zone = commentsHelper.getZone(commentMax.position().left, commentMax.position().top,
        bp.x, bp.y, commentMax.width(), commentMax.height());

      var coords = commentsHelper.getArrowCoords(commentMin, zone);
      var path = new opts.paper.Path();
      path.strokeColor = '#C2E1F5';
      path.strokeWidth = "2";
      path.fillColor = "#FCFCFC";
      path.add(new Point(coords.x0, coords.y0));
      path.add(new Point(coords.x1, coords.y1));
      path.add(new Point(coords.x2, coords.y2));
      path.closed = true;
      opts.paper.project.activeLayer.addChild(path);

      commentMin[0].arrow = path;

      return commentMin;
    },

    // *** Misc methods ***

    redraw:function () {
      opts.paper.view.draw();
    },

    redrawWithThumb:function () {
      this.redraw();
      this.updateSelectedCanvasThumb();
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
      var topLeftScaler = new Path.Oval(new opts.paper.Rectangle(bounds.x - additionalBound - selectRectHalfWidth,
        bounds.y - additionalBound - selectRectHalfWidth, selectRectWidth, selectRectWidth));
      var bottomRightScaler = new Path.Oval(new opts.paper.Rectangle(bounds.x + bounds.width + additionalBound - selectRectHalfWidth,
        bounds.y + bounds.height + additionalBound - selectRectHalfWidth, selectRectWidth, selectRectWidth));
      var topRightScaler = new Path.Oval(new opts.paper.Rectangle(bounds.x + bounds.width + additionalBound - selectRectHalfWidth,
        bounds.y - additionalBound - selectRectHalfWidth, selectRectWidth, selectRectWidth));
      var bottomLeftScaler = new Path.Oval(new opts.paper.Rectangle(bounds.x - additionalBound - selectRectHalfWidth,
        bounds.y + bounds.height + additionalBound - selectRectHalfWidth, selectRectWidth, selectRectWidth));

      if (!selectedTool.commentMin) {
        var removeButton = new Raster(removeImg);
        removeButton.position = new Point(selectionRect.bounds.x + selectionRect.bounds.width + 12, selectionRect.bounds.y - 12);
      }

      var selectionRectGroup = new Group([selectionRect, topLeftScaler, bottomRightScaler, topRightScaler, bottomLeftScaler]);

      selectionRectGroup.theRect = selectionRect;
      selectionRectGroup.topLeftScaler = topLeftScaler;
      selectionRectGroup.bottomRightScaler = bottomRightScaler;
      selectionRectGroup.topRightScaler = topRightScaler;
      selectionRectGroup.bottomLeftScaler = bottomLeftScaler;
      selectionRectGroup.scalers = [topLeftScaler, bottomRightScaler, topRightScaler, bottomLeftScaler];

      if (!selectedTool.commentMin) {
        selectionRectGroup.removeButton = removeButton;
        selectionRectGroup.addChild(removeButton);
      }

      window.room.createTool(selectionRect, {color:"#a0a0aa", width:.5, opacity:1, dashArray:[3, 3]});
      window.room.createTool(topLeftScaler, {color:"#202020", width:1, opacity:1, fillColor:"white"});
      window.room.createTool(bottomRightScaler, {color:"#202020", width:1, opacity:1, fillColor:"white"});
      window.room.createTool(topRightScaler, {color:"#202020", width:1, opacity:1, fillColor:"white"});
      window.room.createTool(bottomLeftScaler, {color:"#202020", width:1, opacity:1, fillColor:"white"});

      if (!selectedTool.commentMin) {
        window.room.createTool(removeButton);
      }

      return selectionRectGroup;
    },

    getScaleFactors:function (item, zx, zy, dx, dy) {
      item = item.arrow ? item.arrow : item;
      var w = item.bounds.width, h = item.bounds.height;

      if (zx == -1 && zy == -1) {
        return {sx:Math.abs((w - dx) / w), sy:Math.abs((h - dy) / h)};
      } else if (zx == 1 && zy == -1) {
        return {sx:Math.abs((w + dx) / w), sy:Math.abs((h - dy) / h)};
      } else if (zx == -1 && zy == 1) {
        return {sx:Math.abs((w - dx) / w), sy:Math.abs((h + dy) / h)};
      } else if (zx == 1 && zy == 1) {
        return {sx:Math.abs((w + dx) / w), sy:Math.abs((h + dy) / h)};
      }
    },

    getReflectZone:function (item, x, y) {
      var itemToScale = item.arrow ? item.arrow : item;

      if (itemToScale.bounds.contains(x, y)) {
        return null; // preserve zone
      }

      var w = itemToScale.bounds.width, h = itemToScale.bounds.height;
      var center = new Point(itemToScale.bounds.topLeft.x + (w / 2), itemToScale.bounds.topLeft.y + (h / 2));
      var cx = center.x, cy = center.y;

      if (x <= cx && y <= cy) {
        var zone = {x:-1, y:-1};
        var point = itemToScale.bounds.bottomRight;
      } else if (x >= cx && y <= cy) {
        zone = {x:1, y:-1};
        point = itemToScale.bounds.bottomLeft;
      } else if (x <= cx && y >= cy) {
        zone = {x:-1, y:1};
        point = itemToScale.bounds.topRight;
      } else if (x >= cx && y >= cy) {
        zone = {x:1, y:1};
        point = itemToScale.bounds.topLeft;
      }

      var dzx = zone.x + item.scaleZone.zx;
      var dzy = zone.y + item.scaleZone.zy;

      if (dzx == 0 && dzy == 0 && w < 3 && h < 3) {
        itemToScale.scale(-1, -1);
        return {zx:zone.x, zy:zone.y, point:point};
      } else if (dzx == 0 && dzy != 0 && w < 3) {
        itemToScale.scale(-1, 1);
        return {zx:zone.x, zy:zone.y, point:point};
      } else if (dzy == 0 && dzx != 0 && h < 3) {
        itemToScale.scale(1, -1);
        return {zx:zone.x, zy:zone.y, point:point};
      } else {
        return null; // do not change the zone
      }
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

    notifyComment:function () {
      window.notificator.notify("Drag to comment an area.");
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
            image.src = "/assets/images/avatar.png";
            $(image).on("load", function () {
              window.room.handleUpload(image);
            })
          }
        }
      });
    },

    elementInArrayContainsPoint:function (array, point) {
      var found = null;
      $(array).each(function () {
        if (this.bounds.contains(point)) {
          found = this;
          return false;
        }
      });

      return found;
    },

    initHotkeys:function () {
      if (isMac()) {
        $(document).bind('keydown.meta_z', function () {
          window.room.prevhistory();
        });

        $(document).bind('keydown.meta_shift_z', function () {
          window.room.nexthistory();
        });
      } else {
        $(document).bind('keydown.ctrl_z', function () {
          window.room.prevhistory();
        });

        $(document).bind('keydown.ctrl_shift_z', function () {
          window.room.nexthistory();
        });
      }

      $(document).bind('keydown.del', function () {
        window.room.removeSelected();
      });

      $(document).bind('keydown.backspace', function () {
        window.room.removeSelected();
      });

      $(document).bind('keydown.left', function () {
        window.room.translateSelected(new Point(-5, 0));
      });

      $(document).bind('keydown.up', function () {
        window.room.translateSelected(new Point(0, -5));
      });

      $(document).bind('keydown.right', function () {
        window.room.translateSelected(new Point(5, 0));
      });

      $(document).bind('keydown.down', function () {
        window.room.translateSelected(new Point(0, 5));
      });

      $(document).bind('keydown.shift_left', function () {
        window.room.translateSelected(new Point(-1, 0));
      });

      $(document).bind('keydown.shift_up', function () {
        window.room.translateSelected(new Point(0, -1));
      });

      $(document).bind('keydown.shift_right', function () {
        window.room.translateSelected(new Point(1, 0));
      });

      $(document).bind('keydown.shift_down', function () {
        window.room.translateSelected(new Point(0, 1));
      })
    },

    findByElementId:function (id) {
      var foundElement = null;
      $(opts.historytools.allHistory).each(function () {
        if (this.commentMin && id == this.commentMin.elementId) {
          foundElement = this;
          return false; // break;
        }

        if (id == this.elementId) {
          foundElement = this;
          return false; // break;
        }
      })
      return foundElement;
    }
  };

  var commentsHelper = {

    SIDE_OFFSET:15,
    CORNER_OFFSET:18,

    getZone:function (left, top, x0, y0, w, h) {
      var c = this.getCommentCoords(left, top, w, h);

      c.xtl = c.xtl / opts.currentScale;
      c.ytl = c.ytl / opts.currentScale;
      c.xtr = c.xtr / opts.currentScale;
      c.ytr = c.ytr / opts.currentScale;
      c.xbl = c.xbl / opts.currentScale;
      c.ybl = c.ybl / opts.currentScale;
      c.xbr = c.xbr / opts.currentScale;
      c.ybr = c.ybr / opts.currentScale;

      var zone = null;

      if (x0 <= c.xtl && y0 <= c.ytl) {
        zone = 1;
      } else if (x0 > c.xtl && x0 < c.xtr && y0 < c.ytl) {
        zone = 2;
      } else if (x0 >= c.xtr && y0 <= c.ytr) {
        zone = 3;
      } else if (x0 < c.xtl && y0 < c.ybl && y0 > c.ytl) {
        zone = 4;
      } else if (x0 >= c.xtl && x0 <= c.xtr && y0 <= c.ybl && y0 >= c.ytl) {
        zone = 5;
      } else if (x0 > c.xtr && y0 < c.ybr && y0 > c.ytr) {
        zone = 6;
      } else if (x0 <= c.xbl && y0 >= c.ybl) {
        zone = 7;
      } else if (x0 > c.xbl && x0 < c.xbr && y0 > c.ybl) {
        zone = 8;
      } else if (x0 >= c.xbr && y0 >= c.ybr) {
        zone = 9;
      }

      return zone;
    },

    getCommentCoords:function (left, top, width, height) {
      return {xtl:left, ytl:top,
        xtr:left + width, ytr:top,
        xbl:left, ybl:top + height,
        xbr:left + width, ybr:top + height};
    },

    getArrowPos:function (zone, c, w, h) {
      var x1 = 0, y1 = 0, x2 = 0, y2 = 0;
      var w2 = w / 2, h2 = h / 2;

      if (zone == 1) {
        x1 = c.xtl;
        y1 = c.ytl + this.CORNER_OFFSET;

        x2 = c.xtl + this.CORNER_OFFSET;
        y2 = c.ytl;
      } else if (zone == 2) {
        x2 = c.xtl + w2 + this.SIDE_OFFSET;
        y2 = c.ytl;

        x1 = c.xtl + w2 - this.SIDE_OFFSET;
        y1 = c.ytl;
      } else if (zone == 3) {
        x1 = c.xtr - this.CORNER_OFFSET;
        y1 = c.ytr;

        x2 = c.xtr;
        y2 = c.ytr + this.CORNER_OFFSET;
      } else if (zone == 4) {
        x1 = c.xtl;
        y1 = c.ytl + h2 + this.SIDE_OFFSET;

        x2 = c.xtl;
        y2 = c.ytl + h2 - this.SIDE_OFFSET;
      } else if (zone == 6) {
        x1 = c.xtr;
        y1 = c.ytr + h2 - this.SIDE_OFFSET;

        x2 = c.xtr;
        y2 = c.ytr + h2 + this.SIDE_OFFSET;
      } else if (zone == 7) {
        x1 = c.xbl + this.CORNER_OFFSET;
        y1 = c.ybl;

        x2 = c.xbl;
        y2 = c.ybl - this.CORNER_OFFSET;
      } else if (zone == 8) {
        x1 = c.xbl + w2 + this.SIDE_OFFSET;
        y1 = c.ybl;

        x2 = c.xbl + w2 - this.SIDE_OFFSET;
        y2 = c.ybl;
      } else if (zone == 9) {
        x1 = c.xbr;
        y1 = c.ybr - this.CORNER_OFFSET;

        x2 = c.xbr - this.CORNER_OFFSET;
        y2 = c.ybr;
      }

      return {x1:x1, y1:y1, x2:x2, y2:y2};
    },

    getArrowCoords:function ($commentMin, zone) {
      var commentMax = $commentMin[0].$maximized;

      if (zone == 5) {
        return null;
      }

      var w = commentMax.width(), h = commentMax.height();
      var c = commentsHelper.getCommentCoords(commentMax.position().left, commentMax.position().top, w, h);

      var bp = this.getArrowBindPoint($commentMin, c.xtl + (w / 2), c.ytl + (h / 2));

      var pos = commentsHelper.getArrowPos(zone, c, w, h);

      return {
        x0:bp.x, y0:bp.y, x1:pos.x1, y1:pos.y1, x2:pos.x2, y2:pos.y2
      };
    },

    getArrowBindPoint:function ($commentMin, cmX, cmY) {
      var rect = $commentMin[0].rect;

      if (!rect) {
        return {x:$commentMin.position().left + ($commentMin.width() / 2),
          y:$commentMin.position().top + ($commentMin.height() / 2)}
      } else {
        rect.xtl = rect.bounds.x;
        rect.ytl = rect.bounds.y;
        rect.xtr = rect.bounds.x + rect.bounds.width;
        rect.ytr = rect.bounds.y;
        rect.xbl = rect.bounds.x;
        rect.ybl = rect.bounds.y + rect.bounds.height;
        rect.xbr = rect.bounds.x + rect.bounds.width;
        rect.ybr = rect.bounds.y + rect.bounds.height;
        rect.center = new Point((rect.bounds.x + (rect.bounds.width / 2)) * opts.currentScale,
          (rect.bounds.y + (rect.bounds.height / 2)) * opts.currentScale);

        if (cmX <= rect.center.x && cmY <= rect.center.y) {
          return {x:rect.xtl, y:rect.ytl};
        } else if (cmX >= rect.center.x && cmY <= rect.center.y) {
          return {x:rect.xtr, y:rect.ytr};
        } else if (cmX <= rect.center.x && cmY >= rect.center.y) {
          return {x:rect.xbl, y:rect.ybr};
        } else if (cmX >= rect.center.x && cmY >= rect.center.y) {
          return {x:rect.xbr, y:rect.ybr};
        }

        return null;
      }
    },

    redrawArrow:function ($commentMin) {
      var commentMax = $commentMin[0].$maximized;
      var rect = $commentMin[0].rect;
      var arrow = $commentMin[0].arrow;

      var cmx = commentMax.position().left + (commentMax.width() / 2);
      var cmy = commentMax.position().top + (commentMax.height() / 2);
      var bp = this.getArrowBindPoint($commentMin, cmx, cmy);

      if (rect) {
        // rebind comment-minimized
        $commentMin.css({left:(bp.x * opts.currentScale) - ($commentMin.width() / 2),
          top:(bp.y * opts.currentScale) - ($commentMin.height() / 2)});
      }

      if (arrow.isHidden) {
        return;
      }

      var zone = commentsHelper.getZone(commentMax.position().left, commentMax.position().top,
        rect ? bp.x : (bp.x / opts.currentScale), rect ? bp.y : (bp.y / opts.currentScale), commentMax.width(), commentMax.height());

      var coords = this.getArrowCoords($commentMin, zone);

      if (coords == null) {
        arrow.opacity = 0;
        return;
      } else {
        arrow.opacity = 1;
      }

      arrow.segments[0].point.x = rect ? coords.x0 : coords.x0 / opts.currentScale;
      arrow.segments[0].point.y = rect ? coords.y0 : coords.y0 / opts.currentScale;
      arrow.segments[1].point.x = coords.x1 / opts.currentScale;
      arrow.segments[1].point.y = coords.y1 / opts.currentScale;
      arrow.segments[2].point.x = coords.x2 / opts.currentScale;
      arrow.segments[2].point.y = coords.y2 / opts.currentScale;

      window.room.redrawWithThumb();
    },

    removeComment:function ($commentmin) {
      if (confirm("Are you sure?")) {
        $commentmin[0].$maximized.hide();
        $commentmin[0].arrow.opacity = 0;
        if ($commentmin[0].rect) {
          $commentmin[0].rect.opacity = 0;
        }
        $commentmin.hide();

        if ($commentmin[0].rect) {
          room.addHistoryTool({type:"remove", tool:$commentmin[0].rect, eligible:true});
        } else {
          room.addHistoryTool({type:"remove", tool:{type:"comment", commentMin:$commentmin}, eligible:true});
        }

        canvasIO.emit("commentRemove", $commentmin.elementId);
        room.redraw();
      }
    },

    hideComment:function ($commentmin) {
      $commentmin[0].$maximized.hide();
      $commentmin[0].arrow.opacity = 0;
      $commentmin[0].arrow.isHidden = true;
      $commentmin.hide();
      if ($commentmin[0].rect) {
        $commentmin[0].rect.opacity = 0;
      }
    },

    showComment:function ($commentmin) {
      $commentmin[0].$maximized.show();
      $commentmin[0].arrow.opacity = 1;
      $commentmin[0].arrow.isHidden = false;
      $commentmin.show();
      if ($commentmin[0].rect) {
        $commentmin[0].rect.opacity = 1;
      }
    },

    foldComment:function ($commentmin) {
      $commentmin[0].$maximized.hide();
      $commentmin[0].arrow.opacity = 0;
      $commentmin[0].arrow.isHidden = true;
      $commentmin.show();

      window.room.redraw();
    },

    unfoldComment:function ($commentmin) {
      $commentmin[0].$maximized.show();
      $commentmin[0].arrow.opacity = 1;
      $commentmin[0].arrow.isHidden = false;

      commentsHelper.redrawArrow($commentmin); // the comment position might have been changed.

      if ($commentmin[0].rect) {
        $commentmin.hide();
      }

      window.room.redraw();
    },

    addCommentText:function (commentMin, text, emit) {
      var commentContent = commentMin[0].$maximized.find(".comment-content");

      commentContent.prepend("<div class='comment-text'>" + text + "</div>");

      if (emit) {
        canvasIO.emit("commentText", {
          elementId:commentMin.elementId,
          text:text
        });
      }
    }

  };

  var canvasIO = io.connect('/canvas', window.copt);

  canvasIO.on('elementUpdate', function (data) {
    window.room.addOrUpdateElement(data.message, false);
  });

  canvasIO.on('elementRemove', function (data) {
    window.room.socketRemoveElement(data.message);
  });

  canvasIO.on('commentUpdate', function (data) {
    window.room.addOrUpdateComment(data.message, false);
  });

  canvasIO.on('commentRemove', function (data) {
    window.room.socketRemoveComment(data.message);
  });

  canvasIO.on('commentText', function (data) {
    window.room.addOrUpdateCommentText(data.message);
  });

  canvasIO.on('eraseCanvas', function () {
    window.room.eraseCanvas();
    window.room.redrawWithThumb();
  });

  canvasIO.on('nextId', function () {
    nextId = nextId + 1;
  });

  window.room = room;
  window.room.helper = helper;

  var removeImg = new Image();
  removeImg.src = "/images/remove.png";
});

$(document).ready(function () {
  if (!currentPage("projects/show")) {
    return;
  }

  window.room.init({paper:paper});
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
