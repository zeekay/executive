var child_process = require('child_process');

function exec(args, options, callback) {
  var err = '',
      out = '',
      proc;

  args = args.split(/\s+/g);
  var cmd = args.shift();

  if (exec.quiet) {
    proc = child_process.spawn(cmd, args);

    proc.stdout.on('data', function(data) {
      out += data;
    });

    proc.stderr.on('data', function(data) {
      err += data;
    });
  } else {
    process.stdin.resume();

    proc = child_process.spawn(cmd, args, {stdio: [process.stdin, process.stdout, process.stderr]});

    process.stdout.on('data', function(data) {
      out += data;
    });

    process.stderr.on('data', function(data) {
      err += data;
    });
  }

  proc.on('exit', function(code) {
    callback(err, out, code);
  });
}

exec.quiet = false;

function wrapper(cmds, options, callback) {
  var complete = 0;

  function iterate() {
    exec(cmds[complete], options, callback);
    complete++;

    if (complete === cmds.length) {
      return;
    } else {
      iterate();
    }
  }

  if (options == null) {
    options = {};
  }

  if (callback == null) {
    callback = function() {};
  }

  if (typeof options === 'function') {
    options = {}
    callback = options;
  }

  if (Array.isArray(cmds)) {
    iterate();
  } else {
    exec(cmds, options, callback);
  }
}

module.exports = wrapper;
