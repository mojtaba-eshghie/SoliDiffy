"use strict";

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }
function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }
function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }
var Point = /*#__PURE__*/_createClass(
/** 
 * An XY coordinate point on the Worksheet with 0.0 being top left corner
 * @class Point
 * @property {Number} x X coordinate of Point
 * @property {Number} y Y coordinate of Point
 * @returns {Point} Excel Point
 */
function Point(x, y) {
  _classCallCheck(this, Point);
  this.x = x;
  this.y = y;
});
module.exports = Point;
//# sourceMappingURL=point.js.map