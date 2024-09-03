const copy = require("@danieldietrich/copy");

module.exports = function(inputs, output) {
	return Promise.all(inputs.map(function(input) {
		return copy(input, output);
	}));
};

