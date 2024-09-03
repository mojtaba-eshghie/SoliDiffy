[![npm version](https://img.shields.io/npm/v/@danieldietrich/copy?logo=npm&style=flat-square)](https://www.npmjs.com/package/@danieldietrich/copy/)[![vulnerabilities](https://img.shields.io/snyk/vulnerabilities/npm/@danieldietrich/copy?style=flat-square)](https://snyk.io/test/npm/@danieldietrich/copy)[![minzipped size](https://img.shields.io/bundlephobia/minzip/@danieldietrich/copy?style=flat-square)](https://bundlephobia.com/result?p=@danieldietrich/copy@latest)
&nbsp;
[![build](https://img.shields.io/travis/danieldietrich/copy?logo=github&style=flat-square)](https://travis-ci.org/danieldietrich/copy/)[![coverage](https://img.shields.io/codecov/c/github/danieldietrich/copy?style=flat-square)](https://codecov.io/gh/danieldietrich/copy/)
&nbsp;
![Platform](https://img.shields.io/badge/platform-Node%20v10%20%28ES8%2fES2017%29-decc47?logo=TypeScript&style=flat-square)
&nbsp;
[![Sponsor](https://img.shields.io/badge/GitHub-💖Sponsors-b5b7b9?logo=github&style=flat-square)](https://github.com/sponsors/danieldietrich)[![donate](https://img.shields.io/badge/Donate-PayPal-blue.svg?style=flat-square)](https://paypal.me/danieldietrich13)[![license](https://img.shields.io/github/license/danieldietrich/copy?style=flat-square)](https://opensource.org/licenses/MIT/)
&nbsp;
[![Follow](https://img.shields.io/twitter/follow/danieldietrich?label=Follow&style=social)](https://twitter.com/danieldietrich/)

# copy

Simple yet powerful copy tool.

The copy tool recursively copies files, directories and links from a source directory to a destination directory.

Features:

* Renaming and moving files and directories
* Filtering paths
* Transformation of file contents
* Performing actions after each path has been copied
* Preserving user permissions
* Overwriting or keeping existing files
* Creating or dereferencing links
* Preserving original timestamps
* Collecting results (size & number of directories, files and links)
* Performing a dry run without writing files
* May be used as drop-in for [fs-extra/copy](https://github.com/jprichardson/node-fs-extra/blob/HEAD/docs/copy.md), see [Options](#options)

The copy tool intentionally does not

* provide a synchronous API
* check for cycles, i.e. if the destination is a subdirectory of the source
* provide a transform API based on streams and chunks
* preserve the timestamp of links (because node does not provide an OS independent API for that purpose)
* rewrite the relative link of symlinks if source and/or destination were renamed or moved

## Installation

```bash
npm i @danieldietrich/copy
```

## Usage

The module supports ES6 _import_ and CommonJS _require_ style.

```ts
import copy from '@danieldietrich/copy';

(async function() {

    // Performs a dry run of copying ./node_modules to ./temp
    const totals = await copy('node_modules', 'temp', { dryRun: true });

    console.log('Totals:', totals);

})();
```

_Totals_ contains information about the copy operation:

```ts
{
    directories: 1338,
    files: 7929,
    symlinks: 48,
    size: 87873775
}
```

The _number_ of directories, files and symlinks corresponds to the source. The _size_ reflects the number of written bytes. In particular, the size might be smaller than the source, if existing files are not ovewritten.

## Examples

### Using copy operations

See also [option precedence](#option-precedence).

```ts
const copy = require('@danieldietrich/copy');
const path = require('path');

(async function() {

    // move dist/ dir contents to parent dir and rename index.js files to index.mjs
    const rename = (source, target) => {
        if (source.stats.isDirectory() && source.path.endsWith('/dist')) {
            return path.dirname(target.path);
        } else if (source.stats.isFile() && source.path.endsWith('/index.js')) {
            return path.join(path.dirname(target.path), 'index.mjs');
        } else {
            return;
        }
    };

    // recursively copy all .js files
    const filter = (source, target) =>
        source.stats.isDirectory() || source.stats.isFile() && source.path.endsWith('.js');

    // transform the contents of all index.mjs files to upper case
    const transform = (data, source, target) => {
        if (source.stats.isFile() && target.path.endsWith('/index.mjs')) {
            return Buffer.from(data.toString('utf8').toUpperCase(), 'utf8');
        } else {
            return data;
        }
    };

    // log some information about copied files
    const afterEach = (source, target, options) => {
        const dryRun = options.dryRun ? '[DRY RUN] ' : '';
        if (source.stats.isDirectory()) {
            console.log(`${dryRun}Created ${target.path}`);
        } else {
            // target.stats is undefined on a dry run if the target does not already exist!
            const size = target.stats?.size || '?';
            console.log(`${dryRun}Copied ${source.path} to ${target.path} (${size} bytes)`);
        }
    };

    const totals = await copy('node_modules', 'temp', {
        rename,
        filter,
        transform,
        afterEach
    });

    console.log('Totals:', totals);

})();
```

### Changing file attributes

In the following example we change the file owner uid. A chgrp or chmod may be performed in a similar way.

```ts
import * as copy from '@danieldietrich/copy';
import * as fs from 'fs';

const { lchown } = fs.promises;

async function changeOwner(src: string, dst: string, uid: number) {
    copy(src, dst, {
        afterEach: async (source, target) => {
            lchown(target.path, uid, source.stats.gid);
        }
    });
}
```

### Implementing a progress indicator

```ts
import * as copy from '@danieldietrich/copy';

async function copyWithProgress(src: string, dst: string, callback: (curr: copy.Totals, sum: copy.Totals) => void) {
    const curr: copy.Totals = {
        directories: 0,
        files: 0,
        symlinks: 0,
        size: 0
    };
    const sum = await copy(src, dst, { dryRun: true });
    const interval = 100; // ms
    let update = Date.now();
    await copy(src, dst, { afterEach: (source) => {
        if (source.stats.isDirectory()) {
            curr.directories += 1;
        } else if (source.stats.isFile()) {
            curr.files += 1;
            curr.size += source.stats.size;
        } else if (source.stats.isSymbolicLink()) {
            curr.symlinks += 1;
            curr.size += source.stats.size;
        }
        if (Date.now() - update >= interval) {
            update = Date.now();
            callback(curr, sum);
        }
    }});
    callback(sum, sum);
}

// usage
(async function() {
    copyWithProgress('node_modules', 'temp', (curr, sum) => {
        const progress = Math.min(100, Math.floor(curr.size / sum.size * 100));
        console.log(`${Number.parseFloat(progress).toFixed(1)} %`);
    });
})();
```

## API

The general signature of _copy_ is:

```ts
async function copy(sourcePath: string, targetPath: string, options?: copy.Options): Promise<copy.Totals>;
```

The public types are:

```ts
// compatible to fs-extra.copy
type Options = {
    overwrite?: boolean;
    errorOnExist?: boolean;
    dereference?: boolean;
    preserveTimestamps?: boolean;
    dryRun?: boolean;
    rename?: (source: Source, target: Target, options: Options) => string | void | Promise<string | void>;
    filter?: (source: Source, target: Target, options: Options) => boolean | Promise<boolean>;
    transform?: (data: Buffer, source: Source, target: Target, options: Options) => Buffer | Promise<Buffer>;
    afterEach?: (source: Source, target: Target, options: Options) => void | Promise<void>;
};

type Source = {
    path: string;
    stats: fs.Stats;
};

type Target = {
    path: string;
    stats?: fs.Stats;
};

type Totals = {
    directories: number;
    files: number;
    symlinks: number;
    size: number; // not size on disk in blocks
};
```

## Options

Copy is a superset of fs-extra/copy. Option names and default values correspond to fs-extra/copy options.

| Option | Description |
| -- | -- |
| <tt>overwrite</tt> | Preserves exising files when set to <tt>false</tt>. Default: <tt>true</tt> |
| <tt>errorOnExist</tt> | Used in conjunction with <tt>overwrite: false</tt>. Default: <tt>false</tt> |
| <tt>dereference</tt> | Copies files if <tt>true</tt>. Default: <tt>false</tt> |
| <tt>preserveTimestamps</tt> | Preserves the original timestamps. Default: <tt>false</tt> |
| <tt>dryRun</tt><sup>*)</sup> | Does not perform any write operations. <tt>afterEach</tt> is called and needs to check <tt>options.dryRun</tt>. Default: <tt>false</tt> |
| <tt>rename</tt><sup>*)</sup> | Optional rename function. A target path is renamed when returning a non-empty <tt>string</tt>, otherwise the original name is taken. When moving a directory to a different location, internally a recursive mkdir might be used. In such a case at least node [v10.12](https://github.com/nodejs/node/blob/master/doc/changelogs/CHANGELOG_V10.md#2018-10-10-version-10120-current-targos) is required. |
| <tt>filter</tt> | Optional path filter. Paths are excluded when returning <tt>false</tt> and included on <tt>true</tt>. |
| <tt>transform</tt><sup>*)</sup> | Optional transformation of file contents. |
| <tt>afterEach</tt><sup>*)</sup> | Optional action that is performed after a path has been copied, even on a dry-run. Please check <tt>options.dryRun</tt> and/or if <tt>target.stats</tt> is defined. |

*) fs-extra does not have this feature

### Option precedence

1. First, the target path is updated by calling the _rename_ function, if present. Please note that the current target path is passed to the function.
2. Then the optional _filter_ function is applied. Because we do this after the target has been renamed, we are able to take the contents of an existing target into account.
3. Next, the optional _transform_ function is called.
4. After the target has been written, the optional _afterEach_ function is called.

---

Copyright &copy; 2020 by [Daniel Dietrich](cafebab3@gmail.com). Released under the [MIT](https://opensource.org/licenses/MIT/) license.
