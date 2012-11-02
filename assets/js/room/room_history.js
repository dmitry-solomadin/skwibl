// Generated by CoffeeScript 1.4.0
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  $(function() {
    var RoomHistory;
    RoomHistory = (function(_super) {

      __extends(RoomHistory, _super);

      function RoomHistory() {
        return RoomHistory.__super__.constructor.apply(this, arguments);
      }

      RoomHistory.prototype.prev = function() {
        var executePrevHistory, item,
          _this = this;
        if (this.room().opts.historyCounter === 0) {
          return;
        }
        executePrevHistory = function(item, reverse) {
          if (item.type === "remove") {
            executePrevHistory(item.tool, true);
          }
          if (item.type === "clear") {
            return $(item.tools).each(function() {
              return executePrevHistory(this, true);
            });
          } else if (item.commentMin) {
            if (reverse) {
              return _this.room().comments.showComment(item.commentMin);
            } else {
              return _this.room().comments.hideComment(item.commentMin);
            }
          } else {
            return _this.room().helper.reverseOpacity(item);
          }
        };
        $("#redoLink").removeClass("disabled");
        this.opts().historyCounter = this.opts().historyCounter - 1;
        item = this.opts().historytools.eligibleHistory[this.opts().historyCounter];
        if (item != null) {
          executePrevHistory(item);
          this.room().redrawWithThumb();
        }
        if (this.opts().historyCounter === 0) {
          return $("#undoLink").addClass("disabled");
        }
      };

      RoomHistory.prototype.next = function() {
        var executeNextHistory, item,
          _this = this;
        if (this.opts().historyCounter === this.opts().historytools.eligibleHistory.length) {
          return;
        }
        executeNextHistory = function(item, reverse) {
          if (item.type === "remove") {
            return executeNextHistory(item.tool, true);
          } else if (item.type === "clear") {
            return $(item.tools).each(function() {
              return executeNextHistory(this, true);
            });
          } else if (item.commentMin) {
            if (reverse) {
              return _this.room().comments.hideComment(item.commentMin);
            } else {
              return _this.room().comments.showComment(item.commentMin);
            }
          } else {
            return _this.room().helper.reverseOpacity(item);
          }
        };
        $("#undoLink").removeClass("disabled");
        item = this.opts().historytools.eligibleHistory[this.opts().historyCounter];
        if (item != null) {
          executeNextHistory(item);
          this.opts().historyCounter = this.opts().historyCounter + 1;
          this.room().redrawWithThumb();
        }
        if (this.opts().historyCounter === this.opts().historytools.eligibleHistory.length) {
          return $("#redoLink").addClass("disabled");
        }
      };

      RoomHistory.prototype.getSelectableTools = function() {
        var selectableTools, tool, _i, _len, _ref;
        selectableTools = [];
        _ref = this.opts().historytools.allHistory;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          tool = _ref[_i];
          if (tool.opacity !== 0) {
            selectableTools.push(tool);
          }
        }
        return selectableTools;
      };

      RoomHistory.prototype.add = function(tool) {
        tool = tool ? tool : this.opts().tool;
        if (this.opts().historyCounter !== this.opts().historytools.eligibleHistory.length) {
          this.opts().historytools.eligibleHistory = this.opts().historytools.eligibleHistory.slice(0, this.room().opts.historyCounter);
        }
        if (tool.eligible) {
          this.opts().historytools.eligibleHistory.push(tool);
        }
        this.opts().historytools.allHistory.push(tool);
        this.opts().historyCounter = this.opts().historytools.eligibleHistory.length;
        if (tool.eligible) {
          $("#undoLink").removeClass("disabled");
          return $("#redoLink").addClass("disabled");
        }
      };

      return RoomHistory;

    })(App.RoomComponent);
    return App.room.history = new RoomHistory;
  });

}).call(this);