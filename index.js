var child_process = require('child_process');

var exec = function(args, options, callback) {
  var err = '',
      out = '',
      complete = 0,
      proc;

  args = args.split(/\s+/g);
  var cmd = args.shift();

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

  function iterate() {
    var complete = 0
  }

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
};

module.exports = exec;
