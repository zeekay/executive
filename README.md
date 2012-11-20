# executive

An easy to use wrapper around `child_process.spawn`, mostly useful for Cakefiles and the like. Sets up pipes for stdout, stderr and stdin so you don't have to. Think of it as a streaming `child_process.exec` with a few extra goodies.

## Examples

```javascript
var exec = require('executive');

exec('ls', function(err, out, code) {
    console.log('Done, no need to echo out as it's piped to stdout by default);
});
```

Also supports simple serial execution of commands:
```javascript
var exec = require('executive');

exec(['ls', 'ls', 'ls'], function(err, out, code) {
    // All three ls commands are called in order.
});
```

In the case of a failure, no additional commands will be executed by default.
```javascript
exec(['ls', 'aaaaa', 'ls'], function(err, out, code) {
    // Only the first command succeeds, the last is never called.
});
```

Arguments are parsed out properly for you:
```javascript
var exec = require('executive');

exec('ls -AGF Foo\\ bar', function(err, out, code) {
    // Note the escaped folder name.
});
```
