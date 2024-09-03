const fs = require("fs");

module.exports = function (inputs, output, options) {
	const to = fs.createWriteStream(output, {flags: 'a'});
	return new Promise(function (resolve, reject) {
		write(inputs.slice(), to, resolve, reject);
	});
};

function write(files, to, resolve, reject) {
	if (files.length) {
		const readStream = fs.createReadStream(files.shift());
		readStream.pipe(to, {
			end: false
		});
		readStream.on('error', reject);
		readStream.on('end', function() {
			write(files, to, resolve, reject);
		});
	} else {
		to.end();
		resolve();
	}
}

