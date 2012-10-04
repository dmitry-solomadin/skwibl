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
      } else if (opts.tooltype == 'comment') {
        var sizes = event.downPoint - event.point;

        if (sizes.x < 0 && sizes.y < 0) {
          var x = event.downPoint.x, y = event.downPoint.y, w = Math.abs(sizes.x), h = Math.abs(sizes.y);
        } else {
          x = event.point.x, y = event.point.y, w = sizes.x, h = sizes.y;
        }

        var rectangle = new Path.RoundRectangle(x, y, w, h, 8, 8);
        opts.commentRect = rectangle;

        this.createTool(rectangle, {width:"2", color:"#C2E1F5"});
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
        $(this.getAllHistoryTools()).each(function () {
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

            if (boundingBox.removeButton) {
              boundingBox.removeButton.position = new Point(bx + bw, by);
            }
          } else {
            opts.selectedTool.translate(event.delta);

            if (opts.selectedTool.selectionRect) {
              opts.selectedTool.selectionRect.translate(event.delta);
            }
          }

          // redraw comment arrow if there is one.
          if (opts.selectedTool.commentMin) {
            commentsHelper.redrawArrow(opts.selectedTool.commentMin);
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
      } else if (opts.tooltype == "comment") {
        var commentMin = window.room.createComment(event.point.x, event.point.y, opts.commentRect);

        if (opts.commentRect) {
          opts.commentRect.commentMin = commentMin;
        }
      }

      if (opts.tooltype == 'straightline' || opts.tooltype == 'arrow' ||
        opts.tooltype == 'circle' || opts.tooltype == 'rectangle') {
        this.addHistoryTool();
      }

      if (opts.tooltype == 'comment') {
        if (opts.commentRect) {
          this.addHistoryTool();
        } else {
          this.addHistoryTool({type:"comment", commentMin:commentMin});
        }

        window.room.setTooltype("select");
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
      window.room.addHistoryTool({
        type:"clear", tools:this.getHistoryTools()
      });
      window.room.helper.setOpacityElems(opts.historytools, 0);

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

      $(this.getAllHistoryTools()).each(function () {
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

    removeSelected:function () {
      if (opts.selectedTool) {
        // add new 'remove' item into history and link it to removed item.
        window.room.addHistoryTool({type:"remove", tool:opts.selectedTool});
        opts.selectedTool.opacity = 0;

        this.unselect();

        this.redraw();
      }
    },

    unselect:function () {
      if (opts.selectedTool && opts.selectedTool.selectionRect) {
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

        if (opts.selectedTool.selectionRect.removeButton &&
          opts.selectedTool.selectionRect.removeButton.bounds.contains(point)) {
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
          window.room.helper.setOpacityElems(item.tools, 1);
        } else if (item.commentMin) {
          var commentRect = item.type != "comment";

          if (!commentRect) {
            item.commentMin.hide()
          }
          item.commentMin[0].$maximized.hide();
          item.commentMin[0].arrow.opacity = 0;
          if (commentRect) {
            item.opacity = 0;
          }
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
          window.room.helper.setOpacityElems(item.tools, 0);
        } else if (item.commentMin) {
          var commentRect = item.type != "comment";

          if (!commentRect) {
            item.commentMin.show()
          }
          item.commentMin[0].$maximized.show();
          item.commentMin[0].arrow.opacity = 1;
          if (commentRect) {
            item.opacity = 1;
          }
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

    getAllHistoryTools:function () {
      return opts.historytools;
    },

    addHistoryTool:function (tool) {
      var tool = tool ? tool : opts.tool;
      if (opts.historyCounter != opts.historytools.length) { // rewrite history
        opts.historytools = opts.historytools.slice(0, opts.historyCounter)
      }

      opts.historytools.push(tool);

      opts.historyCounter = opts.historytools.length;

      $("#undoLink").removeClass("disabled");
      $("#redoLink").addClass("disabled");
    },

    // *** Comments ***

    createComment:function (x, y, rect) {
      var COMMENT_SHIFT_X = 75;
      var COMMENT_SHIFT_Y = -135;

      if (y < 100) {
        COMMENT_SHIFT_X = 75;
        COMMENT_SHIFT_Y = 55;
      }

      var commentMin = $("<div class='comment-minimized" + (rect ? " hide" : "") + "'>&nbsp;</div>");
      commentMin.css({left:x, top:y});

      var commentMax = $("<div class='comment-maximized'></div>");
      commentMax.css({left:x + COMMENT_SHIFT_X, top:y + COMMENT_SHIFT_Y});
      var commentHeader = $("<div class='comment-header'>" +
        "<div class='fr'><span class='comment-minimize'></span><span class='comment-remove'></span></div>" +
        "</div>");

      commentHeader.find(".comment-minimize").on("click", function () {
        window.room.hideComment(commentMin);
      });

      commentHeader.find(".comment-remove").on("click", function () {
        window.room.removeComment(commentMin);
      });

      commentMin.on("mousedown", function () {
        window.room.showComment(commentMin);
      });

      commentMax.append(commentHeader);
      var commentContent = $("<div class='comment-content'>" +
        "<textarea class='comment-reply' placeholder='Type a comment...'></textarea>" +
        "<input type='button' class='btn fr comment-send hide' value='Send'>" +
        "</div>");
      commentMax.append(commentContent);

      commentHeader.drags({onDrag:function (dx, dy) {
        commentMax.css({left:(commentMax.position().left + dx) + "px", top:(commentMax.position().top + dy) + "px"});

        commentsHelper.redrawArrow(commentMin);
      }});

      commentMin.drags({onDrag:function (dx, dy) {
        commentMin.css({left:(commentMin.position().left + dx) + "px", top:(commentMin.position().top + dy) + "px"});

        commentsHelper.redrawArrow(commentMin);
      }});


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
        var commentContent = $(this).parent(".comment-content");
        var commentTextarea = commentContent.find(".comment-reply");
        var commentText = commentTextarea.val();
        commentTextarea.val("");

        commentContent.prepend("<div class='comment-text'>" + commentText + "</div>");
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

    hideComment:function ($commentmin) {
      $commentmin[0].$maximized.hide();
      $commentmin[0].arrow.opacity = 0;
      $commentmin.show();

      window.room.redraw();
    },

    showComment:function ($commentmin) {
      $commentmin[0].$maximized.show();
      $commentmin[0].arrow.opacity = 1;

      if ($commentmin[0].rect) {
        $commentmin.hide();
      }

      window.room.redraw();
    },

    removeComment:function ($comment) {
      if (confirm("Are you sure?")) {
        $comment[0].$maximized.remove();
        $comment[0].arrow.remove();
        $comment.remove();
        window.room.redraw();
      }
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

      if (!selectedTool.commentMin) {
        var removeButton = new Raster(removeImg);
        removeButton.position = new Point(selectionRect.bounds.x + selectionRect.bounds.width, selectionRect.bounds.y);
      }

      var selectionRectGroup = new Group([selectionRect, topLeftRect, bottomRightRect]);

      selectionRectGroup.theRect = selectionRect;
      selectionRectGroup.topLeftRect = topLeftRect;
      selectionRectGroup.bottomRightRect = bottomRightRect;

      if (!selectedTool.commentMin) {
        selectionRectGroup.removeButton = removeButton;
        selectionRectGroup.addChild(removeButton);
      }

      window.room.createTool(selectionRect, {color:"skyblue", width:1, opacity:1, dashArray:[3, 3]});
      window.room.createTool(topLeftRect, {color:"blue", width:1, opacity:1});
      window.room.createTool(bottomRightRect, {color:"blue", width:1, opacity:1});

      if (!selectedTool.commentMin) {
        window.room.createTool(removeButton);
      }

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

      var zone = commentsHelper.getZone(commentMax.position().left, commentMax.position().top,
        rect ? bp.x : (bp.x / opts.currentScale), rect ? bp.y : (bp.y / opts.currentScale), commentMax.width(), commentMax.height());

      if (rect) {
        // rebind comment-minimized
        $commentMin.css({left:(bp.x * opts.currentScale) - ($commentMin.width() / 2),
          top:(bp.y * opts.currentScale) - ($commentMin.height() / 2)});
      }

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
