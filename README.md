# executive

An easy to use wrapper around `child_process.spawn`, useful for Cakefiles and the like. Pipes `stdout`, `stderr` and `stdin` so you don't have to. Think of it as a streaming `child_process.exec` with a few extra goodies.

## Examples

```javascript
var exec = require('executive');

exec('ls', function(err, out, code) {
    // Done, no need to echo out as it's piped to stdout by default.
});
```

Also supports simple serial execution of commands:
```javascript
var exec = require('executive');

exec(['ls', 'ls', 'ls'], function(err, out, code) {
    // All three ls commands are called in order.
});
```

Arguments are parsed out properly for you:
```javascript
var exec = require('executive');

exec('ls -AGF Foo\\ bar', function(err, out, code) {
    // Note the escaped folder name.
});
```

If you'd prefer not to pipe `stdin`, `stdout`, `stderr`:
```javascript
var exec = require('executive');

exec(['ls', 'ls'], {quiet: true}, function(err, out, code) {
    // Not a peep is heard, and both ls commands will be executed.
});
```

...or slightly more succint:

```javascript
exec.quiet(['ls', 'ls'], function(err, out, code) {
    // both commands executed
});
```

In the case of a failure, no additional commands will be executed:
```javascript
exec(['ls', 'aaaaa', 'ls'], function(err, out, code) {
    // Only the first command succeeds, the last is never called.
});
```

...but you can also choose to ignore errors:

```javascript
exec(['ls', 'aaaaaa', 'ls'], {safe: false}, function(err, out, code) {
    // Both commands execute despite aaaaaa not being a valid executable.
});
```

If you need to interact with a program, for instance vim, use interactive mode:
```javascript
exec.interactive('vim', function(err) {
    // Edit your commit message or whatnot
});
```

You even do whatever you want with the child process object:
```javascript
var exec = require('executive');

child = exec.quiet('ls');
child.stdout.on('data', function(data) {
    console.log(data.toString());
});
```

It's especially nice to use in a Cakefile:
```coffeescript
exec = require 'executive'

task 'package', 'Package project', ->
  exec '''
    mkdir -p dist
    rm -rf dist/*
    cp manifest.json dist
    cp -rf assets dist
    cp -rf lib dist
    cp -rf views dist
    zip -r package.zip dist
    rm -rf dist
  '''.split '\n'
```
