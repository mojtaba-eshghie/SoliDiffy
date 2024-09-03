"use strict";

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }
function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }
function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }
var EMU = require('./emu.js');
var CTMarker = /*#__PURE__*/function () {
  /**
   * Element representing an Excel position marker
   * @param {Number} colId Column Number
   * @param {String} colOffset Offset stating how far right to shift the start edge
   * @param {Number} rowId Row Number
   * @param {String} rowOffset Offset stating how far down to shift the start edge
   * @property {Number} col Column number
   * @property {EMU} colOff EMUs of right shift
   * @property {Number} row Row number
   * @property {EMU} rowOff EMUs of top shift
   * @returns {CTMarker} Excel CTMarker 
   */
  function CTMarker(colId, colOffset, rowId, rowOffset) {
    _classCallCheck(this, CTMarker);
    this._col = colId;
    this._colOff = new EMU(colOffset);
    this._row = rowId;
    this._rowOff = new EMU(rowOffset);
  }
  _createClass(CTMarker, [{
    key: "col",
    get: function get() {
      return this._col;
    },
    set: function set(val) {
      if (parseInt(val, 10) !== val || val < 0) {
        throw new TypeError('CTMarker column must be a positive integer');
      }
      this._col = val;
    }
  }, {
    key: "row",
    get: function get() {
      return this._row;
    },
    set: function set(val) {
      if (parseInt(val, 10) !== val || val < 0) {
        throw new TypeError('CTMarker row must be a positive integer');
      }
      this._row = val;
    }
  }, {
    key: "colOff",
    get: function get() {
      return this._colOff.value;
    },
    set: function set(val) {
      this._colOff = new EMU(val);
    }
  }, {
    key: "rowOff",
    get: function get() {
      return this._rowOff.value;
    },
    set: function set(val) {
      this._rowOff = new EMU(val);
    }
  }]);
  return CTMarker;
}();
module.exports = CTMarker;
//# sourceMappingURL=ctMarker.js.map