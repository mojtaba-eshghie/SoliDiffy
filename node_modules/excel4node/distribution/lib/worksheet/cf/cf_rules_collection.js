"use strict";

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }
function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }
function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }
var CfRule = require('./cf_rule');

// -----------------------------------------------------------------------------
var CfRulesCollection = /*#__PURE__*/function () {
  // §18.3.1.18 conditionalFormatting (Conditional Formatting)
  function CfRulesCollection() {
    _classCallCheck(this, CfRulesCollection);
    // rules are indexed by cell refs
    this.rulesBySqref = {};
  }
  _createClass(CfRulesCollection, [{
    key: "count",
    get: function get() {
      return Object.keys(this.rulesBySqref).length;
    }
  }, {
    key: "add",
    value: function add(sqref, ruleConfig) {
      var rules = this.rulesBySqref[sqref] || [];
      var newRule = new CfRule(ruleConfig);
      rules.push(newRule);
      this.rulesBySqref[sqref] = rules;
      return this;
    }
  }, {
    key: "addToXMLele",
    value: function addToXMLele(ele) {
      var _this = this;
      Object.keys(this.rulesBySqref).forEach(function (sqref) {
        var thisEle = ele.ele('conditionalFormatting').att('sqref', sqref);
        _this.rulesBySqref[sqref].forEach(function (rule) {
          rule.addToXMLele(thisEle);
        });
        thisEle.up();
      });
    }
  }]);
  return CfRulesCollection;
}();
module.exports = CfRulesCollection;
//# sourceMappingURL=cf_rules_collection.js.map