"use strict";

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }
function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }
function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }
var NumberFormat = /*#__PURE__*/function () {
  /**
  * @class NumberFormat
  * @param {String} fmt Format of the Number
  * @returns {NumberFormat}
  */
  function NumberFormat(fmt) {
    _classCallCheck(this, NumberFormat);
    this.formatCode = fmt;
    this.id;
  }
  _createClass(NumberFormat, [{
    key: "numFmtId",
    get: function get() {
      return this.id;
    },
    set: function set(id) {
      this.id = id;
    }

    /**
     * @alias NumberFormat.addToXMLele
     * @desc When generating Workbook output, attaches style to the styles xml file
     * @func NumberFormat.addToXMLele
     * @param {xmlbuilder.Element} ele Element object of the xmlbuilder module
     */
  }, {
    key: "addToXMLele",
    value: function addToXMLele(ele) {
      if (this.formatCode !== undefined) {
        ele.ele('numFmt').att('formatCode', this.formatCode).att('numFmtId', this.numFmtId);
      }
    }
  }]);
  return NumberFormat;
}();
module.exports = NumberFormat;
//# sourceMappingURL=numberFormat.js.map