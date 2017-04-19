# executive

[![npm][npm-img]][npm-url]
[![build][build-img]][build-url]
[![dependencies][dependencies-img]][dependencies-url]
[![downloads][downloads-img]][downloads-url]
[![license][license-img]][license-url]
[![chat][chat-img]][chat-url]

> An elegant `child_process.spawn`

Executive is a simple library which provides a more intuitive interface to
[`child_process.spawn`][child_process]. Very useful with build tools and task
runners. Async and sync command execution with built-in serial and parallel
control flow.

## Features
- Promise, Errback, and Synchronous APIs
- Serial execution by default with parallel execution optional
- Automatically pipes `stderr` and `stdout` by default
- Streams `stderr` and `stdout` rather than blocking on command completion
- Automatically uses shell when commands use operators or globs
- New-line delimited strings are automatically executed sequentially
- Easily blend commands, pure functions and promises with built-in control flow

## Install
```bash
$ npm install executive
```

## Usage

No need to echo as `stderr` and `stdout` are piped by default.

```javascript
import exec from 'executive'

exec('uglifyjs foo.js --compress --mangle > foo.min.js')
```

It's easy to be quiet too.
```javascript
exec.quiet('uglifyjs foo.js --compress --mangle > foo.min.js')
```

Callbacks and promises are both supported.
```javascript
exec('ls', (err, stdout, stderr) => console.log(stdout))
exec('ls').then(res => console.log(res.stdout))
```

Automatically serializes commands.

```javascript
exec(['ls', 'ls', 'ls']) // All three ls commands will be executed in order

exec(`ls -l
      ls -lh
      ls -lha`) // Also executed in order
```

Want to execute your commands in parallel? No problem.
```javascript
exec.parallel(['ls', 'ls', 'ls'])
```

Want to collect individual results? Easy.
```javascript
{a, b, c} = await exec.parallel({
  a: 'echo a',
  b: 'echo b',
  c: 'echo c'
})
```

Want to blend in Promises or pure functions? You got it.
```javascript
exec.parallel([
  'ls',

  // Promises can be blended directly in
  exec('ls'),

  // Promises returned by functions are automatically consumed
  () => exec('ls'),

  // Functions which return a string are assumed to be commands
  () => 'ls',

  // Functions and promises can return objects with stdout, stderr or status
  () => ({ stdout: 'huzzah', stderr: '', status: 0 }),

  'ls'
])

```

## Options
Options are passed as the second argument to exec. Helper methods for
`quiet`, `interactive`, `parallel` and `sync` do what you expect.

```javascript
exec('ls', { options: 'quiet' })
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
})
```

#### options.quiet | exec.quiet
##### default `false`

If you'd prefer not to pipe `stdout` and `stderr` set `quiet` to `true`:

```javascript
exec.quiet(['ls', 'ls'], (err, stdout, stderr) => {
  // You can still inspect stdout, stderr of course
})
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
Great with `sake`, `grunt`, `gulp` and other task runners. Even better mixed
with generator-based control flow libraries and/or ES7 `async`/`await`.

Complex example using [`sake`](http://github.com/sakejs/sake-cli):

```coffeescript
task 'package', 'Package project', ->
  # Create dist folder
  await exec '''
    mkdir -p dist/
    rm   -rf dist/*
    '''

  # Copy assets to dist
  await exec.parallel '''
    cp manifest.json dist/
    cp -rf assets/   dist/
    cp -rf lib/      dist/
    cp -rf views/    dist/
    '''

  # Get current git commit hash
  {stdout} = await exec 'git rev-parse HEAD'
  hash     = stdout.substring 0, 8

  # Zip up dist
  exec "zip -r package-#{hash}.zip dist/"
```

You can find more usage examples in the [tests](test/test.coffee).

## License
[MIT][license-url]

[child_process]:    https://nodejs.org/api/child_process.html

[build-img]:        https://img.shields.io/travis/zeekay/executive.svg
[build-url]:        https://travis-ci.org/zeekay/executive
[chat-img]:         https://badges.gitter.im/join-chat.svg
[chat-url]:         https://gitter.im/zeekay/hi
[coverage-img]:     https://coveralls.io/repos/zeekay/executive/badge.svg?branch=master&service=github
[coverage-url]:     https://coveralls.io/github/zeekay/executive?branch=master
[dependencies-img]: https://david-dm.org/zeekay/executive.svg
[dependencies-url]: https://david-dm.org/zeekay/executive
[downloads-img]:    https://img.shields.io/npm/dm/executive.svg
[downloads-url]:    http://badge.fury.io/js/executive
[license-img]:      https://img.shields.io/npm/l/executive.svg
[license-url]:      https://github.com/zeekay/executive/blob/master/LICENSE
[npm-img]:          https://img.shields.io/npm/v/executive.svg
[npm-url]:          https://www.npmjs.com/package/executive
