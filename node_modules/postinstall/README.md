# postinstall

Transform files of Node.js modules with simple and powerful package.json configurations.
Meant to be used by packages lifecycle events:

- `prepare`
  use it to transform devDependencies, while developing or before publishing
- `postinstall`
  use it to deploy dependencies.

## How

Depend on this package:
`npm install postinstall --save`

Configure and run postinstall in package.json:

```json
{
  "name": "mypkg",
  "version": "1.0.0",
  "dependencies": {
    "postinstall": "*"
  },
  "scripts": {
    "postinstall": "postinstall",
    "prepare": "postinstall"
  },
  "prepare": {
    "<modulename>/path": "browserify lib/"
  },
  "postinstall": {
    "<othermodule>/file": "link lib/"
  }
}
```

From there, more dependencies and commands can be added:

```json
{
  "dependencies": {
    "jquery": "3",
    "postinstall": "*"
  },
  "postinstall": {
    "jquery/dist/jquery.slim.min.js": "link public/js/jquery.min.js",
    "jquery/dist/jquery.slim.min.map": "link public/js/jquery.min.js.map"
  },
  "scripts": {
    "postinstall": "postinstall"
  }
}
```

It is also possible to configure postinstall in another json file:

```json
{
  "scripts": {
    "postinstall": "postinstall myconfig.json"
  }
}
```

Here myconfig.json contains:

```json
"postinstall": {
  "jquery/dist/jquery.slim.min.js": "link public/js/jquery.min.js",
  "jquery/dist/jquery.slim.min.map": "link public/js/jquery.min.js.map"
}
```

## Options

- `--allow`, `-a`
  an array of allowed commands. `postinstall -a link -a copy`.
  When unset, all commands are allowed. Available since version 0.3.0.

## Syntax

### Short form

```json
postinstall: {
  "<module>/<input>": "<command> --<option>=<value> <output>"
}
```

### Long form

```json
postinstall: {
 "<module>/<input>": {
  "command": "<command>",
  "output": "<output>",
  "<option>": "<value>"
 }
}
```

### Array form

```json
 "<module>/<input>": [<shortForm | longForm>, ...]
```

input can be a path, with an optional star in its filename.

output can be a path, with an optional star in its filename.

This allows commands to receive multiple files for one output.

### List option

If a command needs to process files in a specific order, the list of files
can be given in the long form option `list`, like this:

```json
"src/": {
 "command": "concat",
 "output": "dest/bundle.js",
 "list": ["two.js", "one.js"]
}
```

This calls `concat(["src/two.js", "src/one.js"], "dest/bundle.js")`.

### Renaming

If a star is present in both input and output file names, it is interpreted
as renaming the input file(s) name(s):

```json
"postinstall": {
  "jquery/dist/*.slim.min.js": "link public/js/*.min.js"
}
```

This will produce the same inputs/outputs as the first example.

## Command

New commands can be added to postinstall and they just need to be available
as `postinstall-<command>` modules exporting a single function:

```json
module.exports = function(inputs, output, options) {
 // inputs is an array of paths
 // output is a path
 // options is an object (possibly empty)
 // can return promise
};
```

Bundled commands: link, copy, concat.

Supported commands:

- zero-config compilers/minifiers: js, css (postinstall-js, postinstall-css)
- browserify (postinstall-browserify)

## Using as a module

`opts` accepts the same options as the cli options and also:

- `cwd`
  resolves paths and modules relative to this directory.
  Defaults to `process.cwd()`.
  Cannot be set from cli. Available since version 0.4.0.

```js
var postinstall = require('postinstall');
postinstall.process(config, {
  allow: ['copy']
}).then(function() {
  // done
}).catch(function(err) {
  console.error(err);
});

// or call manually
postinstall.command(name, input, output, options);
```
