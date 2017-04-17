# executive [![Build Status][travis-image]][travis-url] [![Coverage Status][coveralls-image]][coveralls-url] [![NPM version][npm-image]][npm-url]  [![Gitter chat][gitter-image]][gitter-url]

[![Greenkeeper badge](https://badges.greenkeeper.io/zeekay/executive.svg)](https://greenkeeper.io/)

[![Join the chat at https://gitter.im/zeekay/executive](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/zeekay/executive?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

An elegant `child_process.spawn`. Automatically pipes `stderr` and `stdout` for
you in a non-blocking fashion, making it very useful with build tools and task
runners. Great async support with built-in serial and parallel command execution.

## Features
- Promise, Errback, and Synchronous APIs.
- Serial execution by default with parallel execution optional.
- Automatically pipes `stderr` and `stdout` by default.
- Streams `stderr` and `stdout` rather than blocking on command completion.
- Automatically uses shell when commands use operators or globs.
- New-line delimited strings are automatically executed sequentially.
- Easily blend commands, pure functions and promises with built-in control flow.

## Install
```bash
$ npm install executive
```

## Usage

No need to echo as `stderr` and `stdout` are piped by default.

```javascript
var exec = require('executive');

exec('uglifyjs foo.js --compress --mangle > foo.min.js')
```

It's easy to be quiet too.
```javascript
exec.quiet('uglifyjs foo.js --compress --mangle > foo.min.js')
```

Callbacks and promises are both supported.
```javascript
exec('ls -l', (err, stdout, stderr) => {
    var files = stdout.split('\n');
})

exec('ls -l').then(res => {
    var files = res.stdout.split('\n');
})
```

Automatically serializes commands.

```javascript
exec(['ls', 'ls', 'ls'], (err, stdout, stderr) => {
    // All three ls commands are called in order.
});

exec(`
ls
ls
ls`) // Same
```

Want to execute your commands in parallel? No problem.
```javascript
exec.parallel(['ls', 'ls', 'ls'])
```

Want to blend in Promises or pure functions? No problem.
```javascript
exec.parallel([
    'ls',

    // Promises can be blended directly in.
    exec('ls'),

    // Promises returned by functions are automatically consumed
    function() { return exec('ls') }),

    // Functions which return a string are assumed to be commands
    function() { return 'ls' },

    // Functions and promises can return objects with stdout, stderr or status
    function() { return {stdout: 'huzzah', stderr: '', status: 0} },

    'ls'
])

```

## Options
Options are passed as the second argument to exec. Helper methods for
`quiet`, `interactive`, `parallel` and `sync` do what you expect.

```javascript
exec('ls', {options: quiet})
```

and

```javascript
exec.quiet('ls')
```

are equivalent.

#### options.interactive | exec.interactive
##### default `false`

If you need to interact with a program (your favorite text editor for instance)
or watch the output of a long running process (`tail -f`), or just don't care
about checking `stderr` and `stdout`, set `interactive` to `true`:

```javascript
exec.interactive('vim', err => {
    // Edit your commit message
});
```

#### options.quiet | exec.quiet
##### default `false`

If you'd prefer not to pipe `stdout` and `stderr` set `quiet` to `true`:

```javascript
exec.quiet(['ls', 'ls'], (err, stdout, stderr) => {
    // You can still inspect stdout, stderr of course.
});
```

#### options.sync | exec.sync
##### default `false`
Blocking version of exec. Returns `{stdout, stderr}` or throws an error.

#### options.parallel | exec.parallel
##### default `false`
Uses parallel rather than serial execution of commands.

#### options.shell
##### default `null`
Force a shell to be used for command execution.

#### options.strict
##### default `false`
Any non-zero exit status is treated as an error. Promises will be rejected and
an error will be thrown with `exec.sync` if `syncThrows` is enabled.

#### options.syncThrows
##### default `false`
Will cause `exec.sync` to throw errors rather than returning them.

## Extra
Great with `cake`, `grunt`, `gulp` and other task runners. Even better mixed
with generator-based control flow libraries and/or ES7 `async`/`await`.

Complex example using [`shortcake`](http://github.com/zeekay/shortcake) (which
provides a superset of [Cake](http://coffeescript.org)'s features, including
generator/promise support):

```coffeescript
require 'shortcake'

task 'package', 'Package project', ->
  await exec '''
    mkdir -p dist/
    rm   -rf dist/*
  '''

  await exec.parallel '''
    cp manifest.json dist/
    cp -rf assets/   dist/
    cp -rf lib/      dist/
    cp -rf views/    dist/
  '''

  await exec '''
    zip -r package.zip dist/
    rm -rf dist/
  '''
```

You can find more usage examples in the [tests](test/test.coffee).

[travis-url]:      https://travis-ci.org/zeekay/executive
[travis-image]:    https://img.shields.io/travis/zeekay/executive.svg
[coveralls-url]:   https://coveralls.io/r/zeekay/executive/
[coveralls-image]: https://img.shields.io/coveralls/zeekay/executive.svg
[npm-url]:         https://www.npmjs.com/package/executive
[npm-image]:       https://img.shields.io/npm/v/executive.svg
[downloads-image]: https://img.shields.io/npm/dm/executive.svg
[downloads-url]:   http://badge.fury.io/js/executive
[gitter-image]:    https://badges.gitter.im/zeekay/say-hi.svg
[gitter-url]:      https://gitter.im/zeekay/say-hi
