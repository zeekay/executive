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
      out += data.toString();
    });

    proc.stderr.on('data', function(data) {
      err += data.toString();
    });
  } else {
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
    callback(err, out, code);
  });
}

exec.quiet = false;

function wrapper(cmds, options, callback) {
  var complete = 0;

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
    exec(cmds[complete], options, function(err, out, code) {
      if (code !== 0) {
        return callback(err, out);
      }

      complete++;
      if (complete === cmds.length) {
        callback(err, out);
      } else {
        iterate();
      }
    });
  }

  if (Array.isArray(cmds)) {
    iterate();
  } else {
    exec(cmds, options, callback);
  }
}

module.exports = wrapper;
