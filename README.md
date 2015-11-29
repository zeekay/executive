# executive [![Build Status](https://travis-ci.org/zeekay/executive.svg?branch=master)](https://travis-ci.org/zeekay/executive) [![npm version](https://badge.fury.io/js/executive.svg)](https://badge.fury.io/js/executive)

An elegant `child_process.spawn`. Automatically pipes `stderr` and `stdout` for
you in a non-blocking fashion, making it very useful with build tools and task
runners. Great async support with easy serial and parallel command execution.

## Features
- Node.js callback, Promises and synchronous APIs.
- Serial execution by default, parallel optional.
- Automatically pipes `stderr` and `stdout` by default.
- Streams `stderr` and `stdout` rather than blocking on command completion.
- Automatically uses shell when command uses operators or globs.
- New-line delimited strings are automatically executed sequentially.

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

Callbacks and promises supported.
```javascript
exec.quiet('ls -l', function(err, stdout, stderr) {
    var files = stdout.split('\n');
})

{stdout} = yield exec.quiet('ls -l')
var files = stdout.split('\n');
```

Automatically serializes commands.

```javascript
exec(['ls', 'ls', 'ls'], function(err, stdout, stderr) {
    // All three ls commands are called in order.
});

exec(`
ls
ls
ls`) // Same;
```

Want to execute your commands in parallel? No problem.
```javascript
{stdout} = yield exec.parallel(['ls', 'ls', 'ls'])
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
exec.interactive('vim', function(err) {
    // Edit your commit message or whatnot
});
```

#### options.quiet | exec.quiet
##### default `false`

If you'd prefer not to pipe `stdin`, `stdout`, `stderr` set `quiet` to `false`:
```javascript
exec.quiet(['ls', 'ls'], function(err, stdout, stderr) {
    // Not a peep is heard, and both ls commands will be executed.
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


## Extra credit
Great with `cake`, `grunt`, `gulp` and other task runners.

[Shortcake](http://github.com/zeekay/shortcake) (a superset of Cake) lets you
take advantage of the Promise API to write synchronous looking async tasks:

```coffeescript
require 'shortcake'

task 'package', 'Package project', ->
  yield exec '''
    mkdir -p dist/
    rm   -rf dist/*
  '''

  yield exec.parallel '''
    cp manifest.json dist/
    cp -rf assets/   dist/
    cp -rf lib/      dist/
    cp -rf views/    dist/
  '''

  yield exec '''
    zip -r package.zip dist/
    rm -rf dist/
  '''
```
