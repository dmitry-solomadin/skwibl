// Generated by CoffeeScript 1.4.0
(function() {

  $(function() {
    var RoomSocketHelper;
    RoomSocketHelper = (function() {

      function RoomSocketHelper() {
        var socket,
          _this = this;
        socket = io.connect('/canvas', window.copt);
        App.room.socket = socket;
        socket.on('elementUpdate', function(data) {
          return _this.addOrUpdateElement(data.element);
        });
        socket.on('elementRemove', function(data) {
          return _this.socketRemoveElement(data.message);
        });
        socket.on('commentUpdate', function(data) {
          return _this.addOrUpdateComment(data.element);
        });
        socket.on('commentRemove', function(data) {
          return _this.socketRemoveComment(data.message);
        });
        socket.on('commentText', function(data) {
          return _this.addOrUpdateCommentText(data.element);
        });
        socket.on('fileAdded', function(data) {
          return room.canvas.handleUpload(data.canvasId, data.fileId, false);
        });
        socket.on('switchCanvas', function(data) {
          return room.canvas.selectThumb(room.canvas.findThumbByCanvasId(data.canvasId), false);
        });
        socket.on('eraseCanvas', function() {
          room.canvas.erase();
          return room.redrawWithThumb();
        });
      }

      RoomSocketHelper.prototype.addOrUpdateCommentText = function(element) {
        var foundComment;
        foundComment = room.helper.findByElementId(element.commentId);
        return room.comments.addCommentText(foundComment.commentMin, element.text, element.elementId);
      };

      RoomSocketHelper.prototype.addOrUpdateComment = function(data) {
        var foundComment, updateComment,
          _this = this;
        updateComment = function(comment, updatedComment) {
          comment.commentMin.css({
            left: updatedComment.min.x,
            top: updatedComment.min.y
          });
          comment.commentMin[0].$maximized.css({
            left: updatedComment.max.x,
            top: updatedComment.max.y
          });
          return room.comments.redrawArrow(comment.commentMin);
        };
        foundComment = room.helper.findByElementId(data.elementId);
        if (foundComment) {
          updateComment(foundComment, data);
        } else {
          this.createCommentFromData(data);
        }
        return room.redrawWithThumb();
      };

      RoomSocketHelper.prototype.createCommentFromData = function(comment) {
        var commentMin, rect;
        if (comment.rect) {
          rect = new Path.RoundRectangle(comment.rect.x, comment.rect.y, comment.rect.w, comment.rect.h, 8, 8);
          room.items.create(rect, room.comments.COMMENT_STYLE);
        }
        commentMin = room.comments.create(comment.min.x, comment.min.y, rect, comment.max);
        commentMin.elementId = comment.elementId;
        if (rect) {
          rect.commentMin = commentMin;
          rect.eligible = false;
          room.history.add(rect);
        } else {
          room.history.add({
            type: "comment",
            commentMin: commentMin,
            eligible: false
          });
        }
        return commentMin;
      };

      RoomSocketHelper.prototype.socketRemoveElement = function(data) {
        room.helper.findByElementId(data).remove();
        room.items.unselectIfSelected(data);
        return room.redrawWithThumb();
      };

      RoomSocketHelper.prototype.socketRemoveComment = function(data) {
        var commentMin, element;
        element = room.helper.findByElementId(data);
        commentMin = element.commentMin;
        commentMin[0].$maximized.remove();
        commentMin[0].arrow.remove();
        if (commentMin[0].rect) {
          commentMin[0].rect.remove();
        }
        commentMin.remove();
        room.items.unselectIfSelected(data);
        return room.redrawWithThumb();
      };

      RoomSocketHelper.prototype.addOrUpdateElement = function(element) {
        var foundPath, path;
        foundPath = room.helper.findByElementId(element.elementId);
        if (foundPath) {
          room.items.unselectIfSelected(foundPath.elementId);
          foundPath.removeSegments();
          $(element.segments).each(function() {
            return foundPath.addSegment(room.socketHelper.createSegment(this.x, this.y, this.ix, this.iy, this.ox, this.oy));
          });
          if (foundPath.commentMin) {
            room.comments.redrawArrow(foundPath.commentMin);
          }
        } else {
          path = this.createElementFromData(element);
          room.items.create(path, {
            color: element.strokeColor,
            width: element.strokeWidth,
            opacity: element.opacity
          });
          path.eligible = false;
          room.history.add(path);
        }
        return room.redrawWithThumb();
      };

      RoomSocketHelper.prototype.createSegment = function(x, y, ix, iy, ox, oy) {
        var firstPoint, handleIn, handleOut;
        handleIn = new Point(ix, iy);
        handleOut = new Point(ox, oy);
        firstPoint = new Point(x, y);
        return new Segment(firstPoint, handleIn, handleOut);
      };

      RoomSocketHelper.prototype.createElementFromData = function(data) {
        var path;
        path = new Path();
        $(data.segments).each(function() {
          return path.addSegment(room.socketHelper.createSegment(this.x, this.y, this.ix, this.iy, this.ox, this.oy));
        });
        path.closed = data.closed;
        path.elementId = data.elementId;
        return path;
      };

      RoomSocketHelper.prototype.prepareElementToSend = function(elementToSend) {
        var data, segment, _i, _len, _ref;
        data = {
          canvasId: room.canvas.getSelectedCanvasId(),
          element: {
            elementId: elementToSend.commentMin ? elementToSend.commentMin.elementId : elementToSend.elementId,
            canvasId: room.canvas.getSelectedCanvasId(),
            segments: [],
            closed: elementToSend.closed,
            strokeColor: elementToSend.strokeColor.toCssString(),
            strokeWidth: elementToSend.strokeWidth,
            opacity: elementToSend.opacity
          }
        };
        _ref = elementToSend.segments;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          segment = _ref[_i];
          data.element.segments.push({
            x: segment.point.x,
            y: segment.point.y,
            ix: segment.handleIn.x,
            iy: segment.handleIn.y,
            ox: segment.handleOut.x,
            oy: segment.handleOut.y
          });
        }
        return data;
      };

      RoomSocketHelper.prototype.prepareCommentToSend = function(commentMin) {
        var commentMax, commentRect, data;
        data = {
          canvasId: room.canvas.getSelectedCanvasId(),
          element: {
            elementId: commentMin.elementId,
            min: {
              x: commentMin.position().left,
              y: commentMin.position().top
            }
          }
        };
        commentMax = commentMin[0].$maximized[0];
        if (commentMax) {
          data.element.max = {
            x: $(commentMax).position().left,
            y: $(commentMax).position().top
          };
        }
        commentRect = commentMin[0].rect;
        if (commentRect) {
          data.element.rect = {
            x: commentRect.bounds.x,
            y: commentRect.bounds.y,
            w: commentRect.bounds.width,
            h: commentRect.bounds.height
          };
        }
        return data;
      };

      return RoomSocketHelper;

    })();
    return App.room.socketHelper = new RoomSocketHelper;
  });

}).call(this);
