const pify = require('util').promisify;
const glob = pify(require('glob'));
const fs = require('fs').promises;
const resolveFrom = require('resolve-from');
const resolvePkg = require('resolve-pkg');
const Path = require('path');
const minimist = require('minimist');

Object.assign(exports, {
	prepare, command,
	process(config, opts) {
		if (!opts) opts = {};
		const list = prepare(config, opts);
		return Promise.all(list.map(({ command: cmd, input, output, options }) => {
			return command(cmd, input, output, options, opts);
		}));
	}
});

function prepare(obj, globalOpts) {
	let list = [];
	Object.keys(obj).forEach((input) => {
		const line = obj[input];
		let cmd, output, opts;
		if (Array.isArray(line)) {
			line.forEach((item) => {
				list = list.concat(prepare({[input]: item}, globalOpts));
			});
			return;
		}
		if (typeof line == "object") {
			opts = Object.assign({}, line);
			cmd = line.command;
			output = line.output;
			delete opts.command;
			delete opts.output;
		} else {
			const args = minimist(line.split(' '));
			if (args._.length == 2) {
				cmd = args._[0];
				output = args._[1];
			}
			delete args._;
			opts = args;
		}
		if (!cmd || !output) {
			console.error("Cannot parse postinstall command", line);
			return;
		}

		if (globalOpts.allow) {
			if (!globalOpts.allow.includes(cmd)) {
				console.error("Unauthorized postinstall command", cmd);
				return;
			}
		}
		list.push({
			command: cmd,
			input,
			output,
			options: opts
		});
	});
	return list;
}

function command(cmd, input, output, options = {}, opts = {}) {
	if (!opts.cwd) opts.cwd = process.cwd();
	else opts.cwd = Path.resolve(opts.cwd);

	let srcPath;
	const numComps = input.split('/').length;
	if (input.startsWith('@') && numComps <= 2 || numComps == 1) {
		srcPath = resolveFrom(opts.cwd, input);
	} else {
		srcPath = resolvePkg(input, {
			cwd: opts.cwd
		});
	}
	if (!srcPath) try {
		srcPath = require.resolve(input, {
			paths: [opts.cwd]
		});
	} catch (err) {
		// ignore
	}
	if (!srcPath) srcPath = Path.resolve(opts.cwd, input);
	const srcFile = Path.basename(srcPath);

	let cmdFn;
	if (cmd == "link" || cmd == "copy" || cmd == "concat") {
		cmdFn = require(`./commands/${cmd}`);
	} else {
		cmdFn = require(resolveFrom(opts.cwd, `postinstall-${cmd}`));
	}

	let destDir, destFile;
	if (output.endsWith('/')) {
		destDir = output;
	} else {
		destDir = Path.dirname(output);
		destFile = Path.basename(output);
	}

	const star = srcFile.indexOf('*') >= 0;
	const globstar = srcFile.indexOf('**') >= 0;
	const bundle = star && destFile && destFile.indexOf('*') < 0;
	const nodir = star || globstar;

	destDir = Path.resolve(opts.cwd, destDir);
	assertRooted(opts.cwd, destDir);

	return fs.mkdir(destDir, { recursive: true }).then(() => {
		return glob(srcPath, {
			nosort: true,
			nobrace: true,
			noext: true,
			nodir: nodir
		});
	}).then((paths) => {
		let list = paths;
		if (options.list) {
			if (!nodir && paths.length <= 1) paths.shift();
			if (paths.length == 0) {
				list = options.list.map((path) => {
					return Path.join(srcPath, path);
				});
			}
		}
		if (bundle || options.list) {
			return cmdFn(list, output, options);
		}
		if (paths.length == 0) {
			throw new Error(`${cmd} ${output} but no files found at ${srcPath}`);
		}
		return Promise.all(paths.map((input) => {
			let curDestDir = destDir;
			let outputFile;
			if (globstar) {
				const srcRoot = srcPath.split('**')[0];
				curDestDir = Path.join(destDir, Path.dirname(input.substring(srcRoot.length)));
				outputFile = Path.basename(input);
			} else if (star) {
				const inputFile = Path.basename(input);
				if (!destFile) {
					outputFile = inputFile;
				} else { // bundle == false
					const regEnd = srcFile.endsWith('*') ? '(.+)$' : '([^\\.]+)';
					const reg = new RegExp(srcFile.replace(/\*{1,2}/, regEnd));
					const part = reg.exec(inputFile)[1];
					outputFile = destFile.replace('*', part);
				}
			} else {
				outputFile = destFile || srcFile;
			}
			return fs.mkdir(curDestDir, { recursive: true }).then(() => {
				return cmdFn([input], Path.join(curDestDir, outputFile), options);
			});
		}));
	});
}

function assertRooted(root, path) {
	if (!Path.resolve(path).startsWith(root)) {
		throw new Error(`path is not in root:\n ${root}\n ${path}`);
	}
}
