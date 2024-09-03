#!/usr/bin/env node

var postinstall = require('../');

var fs = require('fs').promises;
var minimist = require('minimist');

var opts = minimist(process.argv, {
	alias: {
		allow: 'a'
	}
});
if (opts.allow && typeof opts.allow == "string") opts.allow = [opts.allow];
delete opts.a;
delete opts.cwd;

var configFile = opts._.length == 3 && opts._[2] || "package.json";
delete opts._;


return fs.readFile(configFile).then(JSON.parse).then(function(obj) {
	return postinstall.process(obj[process.env.npm_lifecycle_event] || {}, opts);
}).then(function() {
	process.exit(0);
}).catch(function(err) {
	console.error(err);
	process.exit(1);
});

