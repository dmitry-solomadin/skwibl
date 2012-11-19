// Generated by CoffeeScript 1.4.0
(function() {

  $(function() {
    var RoomComments;
    RoomComments = (function() {

      function RoomComments() {
        this.SIDE_OFFSET = 15;
        this.CORNER_OFFSET = 18;
        this.COMMENT_RECTANGLE_ROUNDNESS = 8;
        this.COMMENT_STYLE = {
          width: "2",
          color: "#C2E1F5"
        };
      }

      RoomComments.prototype.create = function(x, y, rect, max) {
        var COMMENT_SHIFT_X, COMMENT_SHIFT_Y, bp, commentContent, commentHeader, commentMax, commentMin, coords, max_x, max_y, path, zone,
          _this = this;
        COMMENT_SHIFT_X = 75;
        COMMENT_SHIFT_Y = -135;
        if (y < 100) {
          COMMENT_SHIFT_X = 75;
          COMMENT_SHIFT_Y = 55;
        }
        commentMin = $("<div class=\"comment-minimized " + (rect ? 'hide' : void 0) + "\">&nbsp;</div>");
        commentMin.css({
          left: x,
          top: y
        });
        commentMax = $("<div class='comment-maximized'></div>");
        max_x = max ? max.x : x + COMMENT_SHIFT_X;
        max_y = max ? max.y : y + COMMENT_SHIFT_Y;
        commentMax.css({
          left: max_x,
          top: max_y
        });
        commentHeader = $("<div class='comment-header'>" + "<div class='fr'><span class='comment-minimize'></span><span class='comment-remove'></span></div>" + "</div>");
        commentHeader.find(".comment-minimize").on("click", function() {
          return _this.foldComment(commentMin);
        });
        commentHeader.find(".comment-remove").on("click", function() {
          return _this.removeComment(commentMin);
        });
        commentMin.on("mousedown", function() {
          return _this.unfoldComment(commentMin);
        });
        commentMax.append(commentHeader);
        commentContent = $("<div class='comment-content'>" + "<textarea class='comment-reply' placeholder='Type a comment...'></textarea>" + "<input type='button' class='btn fr comment-send hide' value='Send'>" + "</div>");
        commentMax.append(commentContent);
        commentHeader[0].commentMin = commentMin;
        commentHeader.drags({
          onDrag: function(dx, dy) {
            commentMax.css({
              left: (commentMax.position().left + dx) + "px",
              top: (commentMax.position().top + dy) + "px"
            });
            return _this.redrawArrow(commentMin);
          },
          onAfterDrag: function() {
            room.socket.emit("commentUpdate", room.socketHelper.prepareCommentToSend(commentMin));
            return room.redrawWithThumb();
          }
        });
        commentMin.drags({
          onDrag: function(dx, dy) {
            commentMin.css({
              left: (commentMin.position().left + dx) + "px",
              top: (commentMin.position().top + dy) + "px"
            });
            return _this.redrawArrow(commentMin);
          },
          onAfterDrag: function() {
            room.socket.emit("commentUpdate", room.socketHelper.prepareCommentToSend(commentMin));
            return room.redrawWithThumb();
          }
        });
        $(document).on("click", function(evt) {
          var commentSendButton, _i, _len, _ref;
          _ref = $(".comment-send:visible");
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            commentSendButton = _ref[_i];
            $(commentSendButton).hide();
            _this.redrawArrow(commentMin);
          }
          if (evt.target) {
            return $(evt.target).parent(".comment-content").find(".comment-send").show();
          }
        });
        $(commentMax).find(".comment-send").on("click", function() {
          var commentTextarea;
          commentTextarea = commentMax.find(".comment-reply");
          _this.addCommentText(commentMin, commentTextarea.val(), true);
          return commentTextarea.val("");
        });
        commentMin[0].$maximized = commentMax;
        commentMin[0].rect = rect;
        $("#room-content").prepend(commentMin);
        $("#room-content").prepend(commentMax);
        bp = this.getArrowBindPoint(commentMin, commentMax.position().left + (commentMax.width() / 2), commentMax.position().top + (commentMax.height() / 2));
        zone = this.getZone(commentMax.position().left, commentMax.position().top, bp.x, bp.y, commentMax.width(), commentMax.height());
        coords = this.getArrowCoords(commentMin, zone);
        path = new Path();
        path.strokeColor = '#C2E1F5';
        path.strokeWidth = "2";
        path.fillColor = "#FCFCFC";
        path.add(new Point(coords.x0, coords.y0));
        path.add(new Point(coords.x1, coords.y1));
        path.add(new Point(coords.x2, coords.y2));
        path.closed = true;
        paper.project.activeLayer.addChild(path);
        commentMin[0].arrow = path;
        return commentMin;
      };

      RoomComments.prototype.getZone = function(left, top, x0, y0, w, h) {
        var c;
        c = this.getCommentCoords(left, top, w, h);
        c.xtl = c.xtl / opts.currentScale;
        c.ytl = c.ytl / opts.currentScale;
        c.xtr = c.xtr / opts.currentScale;
        c.ytr = c.ytr / opts.currentScale;
        c.xbl = c.xbl / opts.currentScale;
        c.ybl = c.ybl / opts.currentScale;
        c.xbr = c.xbr / opts.currentScale;
        c.ybr = c.ybr / opts.currentScale;
        if (x0 <= c.xtl && y0 <= c.ytl) {
          return 1;
        }
        if (x0 > c.xtl && x0 < c.xtr && y0 < c.ytl) {
          return 2;
        }
        if (x0 >= c.xtr && y0 <= c.ytr) {
          return 3;
        }
        if (x0 < c.xtl && y0 < c.ybl && y0 > c.ytl) {
          return 4;
        }
        if (x0 >= c.xtl && x0 <= c.xtr && y0 <= c.ybl && y0 >= c.ytl) {
          return 5;
        }
        if (x0 > c.xtr && y0 < c.ybr && y0 > c.ytr) {
          return 6;
        }
        if (x0 <= c.xbl && y0 >= c.ybl) {
          return 7;
        }
        if (x0 > c.xbl && x0 < c.xbr && y0 > c.ybl) {
          return 8;
        }
        if (x0 >= c.xbr && y0 >= c.ybr) {
          return 9;
        }
      };

      RoomComments.prototype.getCommentCoords = function(left, top, width, height) {
        return {
          xtl: left,
          ytl: top,
          xtr: left + width,
          ytr: top,
          xbl: left,
          ybl: top + height,
          xbr: left + width,
          ybr: top + height
        };
      };

      RoomComments.prototype.getArrowPos = function(zone, c, w, h) {
        var h2, w2, x1, x2, y1, y2;
        x1 = 0;
        y1 = 0;
        x2 = 0;
        y2 = 0;
        w2 = w / 2;
        h2 = h / 2;
        switch (zone) {
          case 1:
            x1 = c.xtl;
            y1 = c.ytl + this.CORNER_OFFSET;
            x2 = c.xtl + this.CORNER_OFFSET;
            y2 = c.ytl;
            break;
          case 2:
            x2 = c.xtl + w2 + this.SIDE_OFFSET;
            y2 = c.ytl;
            x1 = c.xtl + w2 - this.SIDE_OFFSET;
            y1 = c.ytl;
            break;
          case 3:
            x1 = c.xtr - this.CORNER_OFFSET;
            y1 = c.ytr;
            x2 = c.xtr;
            y2 = c.ytr + this.CORNER_OFFSET;
            break;
          case 4:
            x1 = c.xtl;
            y1 = c.ytl + h2 + this.SIDE_OFFSET;
            x2 = c.xtl;
            y2 = c.ytl + h2 - this.SIDE_OFFSET;
            break;
          case 6:
            x1 = c.xtr;
            y1 = c.ytr + h2 - this.SIDE_OFFSET;
            x2 = c.xtr;
            y2 = c.ytr + h2 + this.SIDE_OFFSET;
            break;
          case 7:
            x1 = c.xbl + this.CORNER_OFFSET;
            y1 = c.ybl;
            x2 = c.xbl;
            y2 = c.ybl - this.CORNER_OFFSET;
            break;
          case 8:
            x1 = c.xbl + w2 + this.SIDE_OFFSET;
            y1 = c.ybl;
            x2 = c.xbl + w2 - this.SIDE_OFFSET;
            y2 = c.ybl;
            break;
          case 9:
            x1 = c.xbr;
            y1 = c.ybr - this.CORNER_OFFSET;
            x2 = c.xbr - this.CORNER_OFFSET;
            y2 = c.ybr;
        }
        return {
          x1: x1,
          y1: y1,
          x2: x2,
          y2: y2
        };
      };

      RoomComments.prototype.getArrowCoords = function($commentMin, zone) {
        var bp, c, commentMax, h, pos, w;
        commentMax = $commentMin[0].$maximized;
        if (zone === 5) {
          return null;
        }
        w = commentMax.width();
        h = commentMax.height();
        c = this.getCommentCoords(commentMax.position().left, commentMax.position().top, w, h);
        bp = this.getArrowBindPoint($commentMin, c.xtl + (w / 2), c.ytl + (h / 2));
        pos = this.getArrowPos(zone, c, w, h);
        return {
          x0: bp.x,
          y0: bp.y,
          x1: pos.x1,
          y1: pos.y1,
          x2: pos.x2,
          y2: pos.y2
        };
      };

      RoomComments.prototype.getArrowBindPoint = function($commentMin, cmX, cmY) {
        var rect;
        rect = $commentMin[0].rect;
        if (!rect) {
          return {
            x: $commentMin.position().left + ($commentMin.width() / 2),
            y: $commentMin.position().top + ($commentMin.height() / 2)
          };
        } else {
          rect.xtl = rect.bounds.x;
          rect.ytl = rect.bounds.y;
          rect.xtr = rect.bounds.x + rect.bounds.width;
          rect.ytr = rect.bounds.y;
          rect.xbl = rect.bounds.x;
          rect.ybl = rect.bounds.y + rect.bounds.height;
          rect.xbr = rect.bounds.x + rect.bounds.width;
          rect.ybr = rect.bounds.y + rect.bounds.height;
          rect.center = new Point((rect.bounds.x + (rect.bounds.width / 2)) * room.opts.currentScale, (rect.bounds.y + (rect.bounds.height / 2)) * room.opts.currentScale);
          if (cmX <= rect.center.x && cmY <= rect.center.y) {
            return {
              x: rect.xtl,
              y: rect.ytl
            };
          } else if (cmX >= rect.center.x && cmY <= rect.center.y) {
            return {
              x: rect.xtr,
              y: rect.ytr
            };
          } else if (cmX <= rect.center.x && cmY >= rect.center.y) {
            return {
              x: rect.xbl,
              y: rect.ybr
            };
          } else if (cmX >= rect.center.x && cmY >= rect.center.y) {
            return {
              x: rect.xbr,
              y: rect.ybr
            };
          }
          return null;
        }
      };

      RoomComments.prototype.redrawArrow = function($commentMin) {
        var arrow, bp, bpx, bpy, cmx, cmy, commentMax, coords, rect, zone;
        commentMax = $commentMin[0].$maximized;
        rect = $commentMin[0].rect;
        arrow = $commentMin[0].arrow;
        cmx = commentMax.position().left + (commentMax.width() / 2);
        cmy = commentMax.position().top + (commentMax.height() / 2);
        bp = this.getArrowBindPoint($commentMin, cmx, cmy);
        if (rect) {
          $commentMin.css({
            left: (bp.x * opts.currentScale) - ($commentMin.width() / 2),
            top: (bp.y * opts.currentScale) - ($commentMin.height() / 2)
          });
        }
        if (arrow.isHidden) {
          return;
        }
        bpx = rect ? bp.x : bp.x / room.opts.currentScale;
        bpy = rect ? bp.y : bp.y / room.opts.currentScale;
        zone = this.getZone(commentMax.position().left, commentMax.position().top, bpx, bpy, commentMax.width(), commentMax.height());
        coords = this.getArrowCoords($commentMin, zone);
        if (coords === null) {
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
        return room.redraw();
      };

      RoomComments.prototype.translate = function(commentMin, dx, dy) {
        var maximized;
        commentMin.css({
          top: commentMin.position().top + dy,
          left: commentMin.position().left + dx
        });
        commentMin[0].arrow.translate(new Point(dx, dy));
        maximized = commentMin[0].$maximized;
        maximized.css({
          top: maximized.position().top + dy,
          left: maximized.position().left + dx
        });
        if (commentMin[0].rect) {
          return commentMin[0].rect.translate(new Point(dx, dy));
        }
      };

      RoomComments.prototype.removeComment = function($commentmin) {
        var tool;
        if (confirm("Are you sure?")) {
          $commentmin[0].$maximized.hide();
          $commentmin[0].arrow.opacity = 0;
          if ($commentmin[0].rect) {
            $commentmin[0].rect.opacity = 0;
          }
          $commentmin.hide();
          if ($commentmin[0].rect) {
            room.history.add({
              type: "remove",
              tool: $commentmin[0].rect,
              eligible: true
            });
          } else {
            tool = {
              type: "comment",
              commentMin: $commentmin
            };
            room.history.add({
              type: "remove",
              tool: tool,
              eligible: true
            });
          }
          room.socket.emit("commentRemove", $commentmin.elementId);
          return room.redraw();
        }
      };

      RoomComments.prototype.hideComment = function($commentmin) {
        $commentmin[0].$maximized.hide();
        $commentmin[0].arrow.opacity = 0;
        $commentmin[0].arrow.isHidden = true;
        $commentmin.hide();
        if ($commentmin[0].rect) {
          return $commentmin[0].rect.opacity = 0;
        }
      };

      RoomComments.prototype.showComment = function($commentmin) {
        $commentmin[0].$maximized.show();
        $commentmin[0].arrow.opacity = 1;
        $commentmin[0].arrow.isHidden = false;
        $commentmin.show();
        if ($commentmin[0].rect) {
          return $commentmin[0].rect.opacity = 1;
        }
      };

      RoomComments.prototype.foldComment = function($commentmin) {
        $commentmin[0].$maximized.hide();
        $commentmin[0].arrow.opacity = 0;
        $commentmin[0].arrow.isHidden = true;
        $commentmin.show();
        return room.redrawWithThumb();
      };

      RoomComments.prototype.unfoldComment = function($commentmin) {
        $commentmin[0].$maximized.show();
        $commentmin[0].arrow.opacity = 1;
        $commentmin[0].arrow.isHidden = false;
        this.redrawArrow($commentmin);
        if ($commentmin[0].rect) {
          $commentmin.hide();
        }
        return room.redrawWithThumb();
      };

      RoomComments.prototype.addCommentText = function(commentMin, text, emit) {
        var commentContent;
        commentContent = commentMin[0].$maximized.find(".comment-content");
        commentContent.prepend("<div class='comment-text'>" + text + "</div>");
        if (emit) {
          return room.socket.emit("commentText", {
            elementId: commentMin.elementId,
            text: text
          });
        }
      };

      return RoomComments;

    })();
    return App.room.comments = new RoomComments;
  });

}).call(this);