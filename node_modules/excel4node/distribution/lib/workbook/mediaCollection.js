"use strict";

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }
function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }
function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }
var fs = require('fs');
var MediaCollection = /*#__PURE__*/function () {
  function MediaCollection() {
    _classCallCheck(this, MediaCollection);
    this.items = [];
  }
  _createClass(MediaCollection, [{
    key: "add",
    value: function add(item) {
      if (typeof item === 'string') {
        fs.accessSync(item, fs.R_OK);
      }
      this.items.push(item);
      return this.items.length;
    }
  }, {
    key: "isEmpty",
    get: function get() {
      if (this.items.length === 0) {
        return true;
      } else {
        return false;
      }
    }
  }]);
  return MediaCollection;
}();
module.exports = MediaCollection;
//# sourceMappingURL=mediaCollection.js.map