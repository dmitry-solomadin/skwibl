// Generated by CoffeeScript 1.4.0
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  $(function() {
    var RoomItems;
    RoomItems = (function(_super) {

      __extends(RoomItems, _super);

      function RoomItems() {
        this.removeImg = new Image();
        this.removeImg.src = "/images/remove.png";
      }

      RoomItems.prototype.create = function(tool, settings) {
        if (!settings) {
          settings = {};
        }
        if (!settings.justCreate) {
          this.opts().tool = tool;
        }
        this.opts().tool.strokeColor = settings.color ? settings.color : this.opts().color;
        this.opts().tool.strokeWidth = settings.width ? settings.width : this.opts().defaultWidth;
        if (settings.fillColor) {
          this.opts().tool.fillColor = settings.fillColor;
        }
        this.opts().tool.opacity = settings.opacity ? settings.opacity : this.opts().opacity;
        return this.opts().tool.dashArray = settings.dashArray ? settings.dashArray : void 0;
      };

      RoomItems.prototype.removeSelected = function() {
        if (this.opts().selectedTool) {
          this.room().history.add({
            type: "remove",
            tool: this.opts().selectedTool,
            eligible: true
          });
          this.opts().selectedTool.opacity = 0;
          this.room().socket.emit("elementRemove", this.opts().selectedTool.elementId);
          this.unselect();
          return this.room().redrawWithThumb();
        }
      };

      RoomItems.prototype.translateSelected = function(deltaPoint) {
        if (this.opts().selectedTool) {
          this.opts().selectedTool.translate(deltaPoint);
          if (this.opts().selectedTool.selectionRect) {
            this.opts().selectedTool.selectionRect.translate(deltaPoint);
          }
          return this.room().redrawWithThumb();
        }
      };

      RoomItems.prototype.unselectIfSelected = function(elementId) {
        if (this.opts().selectedTool && this.opts().selectedTool.selectionRect && this.opts().selectedTool.elementId === elementId) {
          return this.unselect();
        }
      };

      RoomItems.prototype.unselect = function() {
        if (this.opts().selectedTool && this.opts().selectedTool.selectionRect) {
          this.opts().selectedTool.selectionRect.remove();
        }
        return this.opts().selectedTool = null;
      };

      RoomItems.prototype.testSelect = function(point) {
        var alreadySelected, element, previousSelectedTool, selectTimeDelta, selected, _i, _len, _ref;
        selectTimeDelta = this.opts().selectTime ? new Date().getTime() - this.opts().selectTime : void 0;
        this.opts().selectTime = new Date().getTime();
        alreadySelected = this.opts().selectedTool && this.opts().selectedTool.selectionRect;
        selected = false;
        if (alreadySelected) {
          if (this.room().helper.elementInArrayContainsPoint(this.opts().selectedTool.selectionRect.scalers, point) || (this.opts().selectedTool.selectionRect.removeButton && this.opts().selectedTool.selectionRect.removeButton.bounds.contains(point))) {
            selected = true;
          }
        }
        if (selectTimeDelta > 750 && alreadySelected && this.opts().selectedTool.selectionRect.bounds.contains(point)) {
          selected = true;
        }
        if (!selected) {
          previousSelectedTool = this.opts().selectedTool;
          _ref = this.room().history.getSelectableTools();
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            element = _ref[_i];
            if (element.isImage || element.type) {
              continue;
            }
            if (element.bounds.contains(point)) {
              this.opts().selectedTool = element;
              selected = true;
            }
            if (selectTimeDelta < 750 && this.opts().selectedTool && previousSelectedTool) {
              if (this.opts().selectedTool.id === previousSelectedTool.id) {
                continue;
              } else {
                break;
              }
            }
          }
        }
        if (!selected) {
          return this.opts().selectedTool = null;
        }
      };

      RoomItems.prototype.drawSelectRect = function(point) {
        var tool;
        tool = this.opts().selectedTool;
        if (tool) {
          tool.selectionRect = this.createSelectionRectangle(tool);
          $("#removeSelected").removeClass("disabled");
          tool.scalersSelected = true;
          if (tool.selectionRect.topLeftScaler.bounds.contains(point)) {
            tool.scaleZone = {
              zx: -1,
              zy: -1,
              point: tool.bounds.bottomRight
            };
          } else if (tool.selectionRect.bottomRightScaler.bounds.contains(point)) {
            tool.scaleZone = {
              zx: 1,
              zy: 1,
              point: tool.bounds.topLeft
            };
          } else if (tool.selectionRect.topRightScaler.bounds.contains(point)) {
            tool.scaleZone = {
              zx: 1,
              zy: -1,
              point: tool.bounds.bottomLeft
            };
          } else if (tool.selectionRect.bottomLeftScaler.bounds.contains(point)) {
            tool.scaleZone = {
              zx: -1,
              zy: 1,
              point: tool.bounds.topRight
            };
          } else {
            tool.scalersSelected = false;
          }
          if (tool.selectionRect.removeButton && tool.selectionRect.removeButton.bounds.contains(point)) {
            return this.removeSelected();
          }
        }
      };

      RoomItems.prototype.createSelectionRectangle = function(selectedTool) {
        var addBound, bottomLeftScaler, bottomRightScaler, bounds, dashArray, halfWidth, removeButton, selectRect, selectionRectGroup, topLeftScaler, topRightScaler, width;
        bounds = selectedTool.bounds;
        addBound = parseInt(selectedTool.strokeWidth / 2);
        selectRect = new Path.Rectangle(bounds.x - addBound, bounds.y - addBound, bounds.width + (addBound * 2), bounds.height + (addBound * 2));
        width = 8;
        halfWidth = width / 2;
        topLeftScaler = new Path.Oval(new Rectangle(bounds.x - addBound - halfWidth, bounds.y - addBound - halfWidth, width, width));
        bottomRightScaler = new Path.Oval(new Rectangle(bounds.x + bounds.width + addBound - halfWidth, bounds.y + bounds.height + addBound - halfWidth, width, width));
        topRightScaler = new Path.Oval(new Rectangle(bounds.x + bounds.width + addBound - halfWidth, bounds.y - addBound - halfWidth, width, width));
        bottomLeftScaler = new Path.Oval(new Rectangle(bounds.x - addBound - halfWidth, bounds.y + bounds.height + addBound - halfWidth, width, width));
        if (!selectedTool.commentMin) {
          removeButton = new Raster(this.removeImg);
          removeButton.position = new Point(selectRect.bounds.x + selectRect.bounds.width + 12, selectRect.bounds.y - 12);
        }
        selectionRectGroup = new Group([selectRect, topLeftScaler, bottomRightScaler, topRightScaler, bottomLeftScaler]);
        selectionRectGroup.theRect = selectRect;
        selectionRectGroup.topLeftScaler = topLeftScaler;
        selectionRectGroup.bottomRightScaler = bottomRightScaler;
        selectionRectGroup.topRightScaler = topRightScaler;
        selectionRectGroup.bottomLeftScaler = bottomLeftScaler;
        selectionRectGroup.scalers = [topLeftScaler, bottomRightScaler, topRightScaler, bottomLeftScaler];
        if (!selectedTool.commentMin) {
          selectionRectGroup.removeButton = removeButton;
          selectionRectGroup.addChild(removeButton);
        }
        dashArray = [3, 3];
        this.create(selectRect, {
          color: "#a0a0aa",
          width: 0.5,
          opacity: 1,
          dashArray: dashArray
        });
        this.create(topLeftScaler, {
          color: "#202020",
          width: 1,
          opacity: 1,
          fillColor: "white"
        });
        this.create(bottomRightScaler, {
          color: "#202020",
          width: 1,
          opacity: 1,
          fillColor: "white"
        });
        this.create(topRightScaler, {
          color: "#202020",
          width: 1,
          opacity: 1,
          fillColor: "white"
        });
        this.create(bottomLeftScaler, {
          color: "#202020",
          width: 1,
          opacity: 1,
          fillColor: "white"
        });
        if (!selectedTool.commentMin) {
          this.create(removeButton);
        }
        return selectionRectGroup;
      };

      RoomItems.prototype.doScale = function(tool, sx, sy, scalePoint) {
        var transformMatrix;
        transformMatrix = new Matrix().scale(sx, sy, scalePoint);
        if (transformMatrix._d === 0 || transformMatrix._a === 0) {
          return;
        }
        if (tool.tooltype === "arrow") {
          tool.arrow.scale(sx, sy, scalePoint);
          tool.drawTriangle();
        } else {
          tool.transform(transformMatrix);
        }
        return tool.selectionRect.theRect.transform(transformMatrix);
      };

      RoomItems.prototype.getScaleFactors = function(item, zx, zy, dx, dy) {
        var h, w;
        item = item.arrow ? item.arrow : item;
        w = item.bounds.width;
        h = item.bounds.height;
        if (zx === -1 && zy === -1) {
          return {
            sx: Math.abs((w - dx) / w),
            sy: Math.abs((h - dy) / h)
          };
        }
        if (zx === 1 && zy === -1) {
          return {
            sx: Math.abs((w + dx) / w),
            sy: Math.abs((h - dy) / h)
          };
        }
        if (zx === -1 && zy === 1) {
          return {
            sx: Math.abs((w - dx) / w),
            sy: Math.abs((h + dy) / h)
          };
        }
        if (zx === 1 && zy === 1) {
          return {
            sx: Math.abs((w + dx) / w),
            sy: Math.abs((h + dy) / h)
          };
        }
      };

      RoomItems.prototype.getReflectZone = function(item, x, y) {
        var center, cx, cy, dzx, dzy, h, itemToScale, w, zone;
        itemToScale = item.arrow ? item.arrow : item;
        if (itemToScale.bounds.contains(x, y)) {
          return null;
        }
        w = itemToScale.bounds.width;
        h = itemToScale.bounds.height;
        center = new Point(itemToScale.bounds.topLeft.x + (w / 2), itemToScale.bounds.topLeft.y + (h / 2));
        cx = center.x;
        cy = center.y;
        if (x <= cx && y <= cy) {
          zone = {
            zx: -1,
            zy: -1,
            point: itemToScale.bounds.bottomRight
          };
        } else if (x >= cx && y <= cy) {
          zone = {
            zx: 1,
            zy: -1,
            point: itemToScale.bounds.bottomLeft
          };
        } else if (x <= cx && y >= cy) {
          zone = {
            zx: -1,
            zy: 1,
            point: itemToScale.bounds.topRight
          };
        } else if (x >= cx && y >= cy) {
          zone = {
            zx: 1,
            zy: 1,
            point: itemToScale.bounds.topLeft
          };
        }
        dzx = zone.zx + item.scaleZone.zx;
        dzy = zone.zy + item.scaleZone.zy;
        if (dzx === 0 && dzy === 0 && w < 3 && h < 3) {
          itemToScale.scale(-1, -1);
          return zone;
        } else if (dzx === 0 && dzy !== 0 && w < 3) {
          itemToScale.scale(-1, 1);
          return zone;
        } else if (dzy === 0 && dzx !== 0 && h < 3) {
          itemToScale.scale(1, -1);
          return zone;
        } else {
          return null;
        }
      };

      return RoomItems;

    })(App.RoomComponent);
    return App.room.items = new RoomItems;
  });

}).call(this);
