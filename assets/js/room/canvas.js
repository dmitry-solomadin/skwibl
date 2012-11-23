// Generated by CoffeeScript 1.4.0
(function() {

  $(function() {
    var RoomCanvas;
    RoomCanvas = (function() {

      function RoomCanvas() {}

      RoomCanvas.prototype.init = function() {
        var callback, cid, initialOpts, selectedCid, thumb, _i, _len, _ref,
          _this = this;
        selectedCid = this.getSelectedCanvasId();
        _ref = this.getThumbs();
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          thumb = _ref[_i];
          callback = function(canvasId) {
            if (selectedCid === canvasId) {
              paper.projects[1].activate();
            } else {
              room.initOpts(canvasId);
              paper.projects[0].activate();
            }
            _this.updateThumb(canvasId);
            _this.clearCopyCanvas();
            return paper.projects[1].activate();
          };
          cid = $(thumb).data("cid");
          if (selectedCid === cid) {
            paper.projects[1].activate();
          } else {
            paper.projects[0].activate();
          }
          this.addImage($(thumb).data("fid"), (function(canvasId) {
            return function() {
              return callback(canvasId);
            };
          })(cid));
          paper.projects[1].activate();
        }
        initialOpts = this.findCanvasOptsById(selectedCid);
        return room.setOpts(initialOpts);
      };

      RoomCanvas.prototype.clear = function() {
        var element, _i, _len, _ref;
        room.history.add({
          type: "clear",
          tools: room.history.getSelectableTools(),
          eligible: true
        });
        _ref = opts.historytools.allHistory;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          element = _ref[_i];
          if (!element.type) {
            element.opacity = 0;
          }
          if (element.commentMin) {
            room.comments.hideComment(element.commentMin);
          }
        }
        room.items.unselect();
        room.redrawWithThumb();
        return room.socket.emit("eraseCanvas");
      };

      RoomCanvas.prototype.erase = function() {
        var element, _i, _len, _ref;
        _ref = opts.historytools.allHistory;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          element = _ref[_i];
          if (!element.type) {
            element.remove();
          }
          if (element.commentMin) {
            room.comments.hideComment(element.commentMin);
          }
        }
        return room.redraw();
      };

      RoomCanvas.prototype.eraseCompletely = function() {
        var child, _i, _len, _ref;
        _ref = paper.project.activeLayer.children;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          child = _ref[_i];
          child.remove();
        }
        return room.redraw();
      };

      RoomCanvas.prototype.clearCopyCanvas = function() {
        var child, _i, _len, _ref, _results;
        _ref = paper.projects[0].activeLayer.children;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          child = _ref[_i];
          _results.push(child.remove());
        }
        return _results;
      };

      RoomCanvas.prototype.restore = function() {
        var element, _i, _len, _ref, _results;
        _ref = opts.historytools.allHistory;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          element = _ref[_i];
          if (!this.type) {
            paper.project.activeLayer.addChild(element);
          }
          if (element.commentMin) {
            _results.push(room.comments.showComment(element.commentMin));
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      };

      RoomCanvas.prototype.setScale = function(scale) {
        var commentMax, element, finalScale, transformMatrix, _i, _len, _ref;
        finalScale = scale / opts.currentScale;
        opts.currentScale = scale;
        transformMatrix = new Matrix(finalScale, 0, 0, finalScale, 0, 0);
        paper.project.activeLayer.transform(transformMatrix);
        _ref = opts.historytools.allHistory;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          element = _ref[_i];
          if (element.commentMin) {
            element.commentMin.css({
              top: element.commentMin.position().top * finalScale,
              left: element.commentMin.position().left * finalScale
            });
            commentMax = element.commentMin[0].$maximized;
            commentMax.css({
              top: commentMax.position().top * finalScale,
              left: commentMax.position().left * finalScale
            });
            room.comments.redrawArrow(element.commentMin);
          }
        }
        return room.redraw();
      };

      RoomCanvas.prototype.addScale = function() {
        return this.setScale(opts.currentScale + 0.1);
      };

      RoomCanvas.prototype.subtractScale = function() {
        return this.setScale(opts.currentScale - 0.1);
      };

      RoomCanvas.prototype.handleUpload = function(canvasId, fileId, emit) {
        var _this = this;
        if (opts.fileId) {
          this.addNewThumbAndSelect(canvasId);
        }
        return this.addImage(fileId, function() {
          _this.updateSelectedThumb();
          if (emit) {
            return room.socket.emit("fileAdded", {
              canvasId: canvasId,
              fileId: fileId
            });
          }
        });
      };

      RoomCanvas.prototype.addImage = function(fileId, callback) {
        var activeProject, image;
        image = new Image();
        image.src = "/files/" + ($("#pid").val()) + "/" + fileId;
        activeProject = paper.project;
        return $(image).on("load", function() {
          var img;
          img = new Raster(image);
          img.isImage = true;
          activeProject.activeLayer.insertChild(0, img);
          img.size.width = image.width;
          img.size.height = image.height;
          img.position = paper.view.center;
          if (callback != null) {
            callback();
          }
          opts.fileId = fileId;
          opts.image = img;
          return room.history.add(img);
        });
      };

      RoomCanvas.prototype.addNewThumb = function(canvasId) {
        var thumb;
        thumb = $("<a href='#' data-cid='" + canvasId + "'><canvas width='80' height='60'></canvas></a>");
        return $("#canvasSelectDiv").append(thumb);
      };

      RoomCanvas.prototype.addNewThumbAndSelect = function(canvasId) {
        this.eraseCompletely();
        room.initOpts(canvasId);
        this.addNewThumb(canvasId);
        $("#canvasSelectDiv a").removeClass("canvasSelected");
        return $("#canvasSelectDiv a:last").addClass("canvasSelected");
      };

      RoomCanvas.prototype.updateThumb = function(canvasId) {
        var canvas, cvh, cvw, i, shift, sy, th, thumb, thumbContext, transformMatrix, tw, _i;
        thumb = $("#canvasSelectDiv a[data-cid='" + canvasId + "'] canvas");
        thumbContext = thumb[0].getContext('2d');
        canvas = paper.project.view.element;
        cvw = $(canvas).width();
        cvh = $(canvas).height();
        tw = $(thumb).width();
        th = $(thumb).height();
        sy = th / cvh;
        transformMatrix = new Matrix(sy / opts.currentScale, 0, 0, sy / opts.currentScale, 0, 0);
        paper.project.activeLayer.transform(transformMatrix);
        room.redraw();
        shift = -((sy * cvw) - tw) / 2;
        thumbContext.clearRect(0, 0, tw, th);
        for (i = _i = 0; _i <= 5; i = ++_i) {
          thumbContext.drawImage(canvas, shift, 0);
        }
        transformMatrix = new Matrix(opts.currentScale / sy, 0, 0, opts.currentScale / sy, 0, 0);
        paper.project.activeLayer.transform(transformMatrix);
        return room.redraw();
      };

      RoomCanvas.prototype.updateSelectedThumb = function() {
        return this.updateThumb(this.getSelectedCanvasId());
      };

      RoomCanvas.prototype.getSelectedCanvasId = function() {
        return this.getSelected().data("cid");
      };

      RoomCanvas.prototype.getSelected = function() {
        return $(".canvasSelected");
      };

      RoomCanvas.prototype.getThumbs = function() {
        return $("#canvasSelectDiv a");
      };

      RoomCanvas.prototype.selectThumb = function(anchor, emit) {
        var canvasOpts, cid;
        if ($(anchor).hasClass("canvasSelected")) {
          return;
        }
        $("#canvasSelectDiv a").removeClass("canvasSelected");
        cid = $(anchor).data("cid");
        canvasOpts = this.findCanvasOptsById(cid);
        if (!canvasOpts) {
          alert("No canvas opts by given canvasId=" + cid);
        }
        this.erase();
        room.setOpts(canvasOpts);
        this.restore();
        $(anchor).addClass("canvasSelected");
        if (emit) {
          room.socket.emit("switchCanvas", cid);
        }
        return room.redraw();
      };

      RoomCanvas.prototype.findCanvasOptsById = function(canvasId) {
        var savedOpt, _i, _len, _ref;
        console.log(room.savedOpts);
        _ref = room.savedOpts;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          savedOpt = _ref[_i];
          if (savedOpt.canvasId === canvasId) {
            return savedOpt;
          }
        }
        return null;
      };

      return RoomCanvas;

    })();
    return App.room.canvas = new RoomCanvas;
  });

}).call(this);
