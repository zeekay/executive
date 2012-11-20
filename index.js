var child_process = require('child_process');

function exec(args, callback) {
  var err = '',
      out = '',
      proc;

  // Split arguments from command
  args = args.split(/\s+/g);
  var cmd = args.shift();

  if (exec.quiet) {
    // Do not echo to stdout/stderr
    proc = child_process.spawn(cmd, args);

    proc.stdout.on('data', function(data) {
      out += data.toString();
    });

    proc.stderr.on('data', function(data) {
      err += data.toString();
    });
  } else {
    // Echo to stdout/stderr and handle stdin
    process.stdin.resume();

    proc = child_process.spawn(cmd, args, {stdio: [process.stdin, process.stdout, process.stderr]});

    process.stdout.on('data', function(data) {
      out += data.toString();
    });

    process.stderr.on('data', function(data) {
      err += data.toString();
    });
  }

  proc.on('exit', function(code) {
    process.stdin.pause();
    callback(err, out, code);
  });
}

// A couple of global options
exec.quiet = false;
exec.safe = true;

// Wrapper function that handles exec being called with only one command or several
function wrapper(cmds, options, callback) {
  var complete = 0;

  // If options is a function, assume we are called with only two arguments
  if (typeof options === 'function') {
    callback = options;
    options = {};
  }

  // Default options, callback
  if (options == null) {
    options = {};
  }

  if (callback == null) {
    callback = function() {};
  }

  // Override defaults if options.quiet or options.safe are specified
  if (options.quiet != null) {
    exec.quiet = options.quiet;
  }

  if (options.safe != null) {
    exec.safe = options.safe;
  }

  // Iterate over list of cmds, calling each in order as long as all of them return without errors
  function iterate() {
    exec(cmds[complete], function(err, out, code) {
      if (exec.safe && code !== 0) {
        return callback(err, out, code);
      }

      complete++;
      if (complete === cmds.length) {
        callback(err, out, code);
      } else {
        iterate();
      }
    });
  }

  // If we are passed an array of commands, call each in serial, otherwise exec immediately.
  if (Array.isArray(cmds)) {
    iterate();
  } else {
    exec(cmds, callback);
  }
}

module.exports = wrapper;
