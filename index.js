var child_process = require('child_process');

function parseShell(s) {
  return s.match(/(['"])((\\\1|[^\1])*?)\1|(\\ |\S)+/g).map(function(s) {
    if (/^'/.test(s)) {
      return s.replace(/^'|'$/g, '')
              .replace(/\\(["'\\$`(){}!#&*|])/g, '$1');
    } else if (/^"/.test(s)) {
      return s.replace(/^"|"$/g, '')
              .replace(/\\(["'\\$`(){}!#&*|])/g, '$1');
    } else {
      return s.replace(/\\([ "'\\$`(){}!#&*|])/g, '$1');
    }
  });
}

function exec(args, callback) {
  var env = process.env,
      err = '',
      out = '',
      cmd,
      _var,
      arg,
      proc;

  // Reverse arguments, javascript does not support lookbehind assertions so
  // we'll use a lookahead assertion instead in our regex later.
  args = args.split('').reverse().join('');
  // Split on whitespace, respecting escaped spaces.
  args = args.split(/\s+(?!\\)/g);
  // Correct order of arguments.
  args.reverse();

  // Correct order of characters, removing escapes
  for (var i=0; i<args.length; i++) {
    args[i] = args[i].split('').reverse().join('').replace('\\ ', ' ');
  }

  // Parse out command and any enviromental variables
  while ((cmd = args.shift()).indexOf('=') != -1) {
    _var = cmd.split('=');

    if (_var.length != 2)
      throw new Error('Invalid enviromental variable specified.');

    env[_var[0]] = _var[1];

    if (args.length === 0)
      throw new Error('No command specified.')
  }

  args = parseShell(args.join(' '));

  if (exec.quiet) {
    // Do not echo to stdout/stderr
    proc = child_process.spawn(cmd, args, {env: env});

    proc.stdout.on('data', function(data) {
      out += data.toString();
    });

    proc.stderr.on('data', function(data) {
      err += data.toString();
    });
  } else {
    // Echo to stdout/stderr and handle stdin
    process.stdin.resume();

    proc = child_process.spawn(cmd, args, {env: env, stdio: [process.stdin, process.stdout, process.stderr]});
    proc.setMaxListeners(0);

    var stdoutListener = function(data) {
      out += data.toString();
    };

    var stderrListener = function(data) {
      err += data.toString();
    };

    process.stdout.on('data', stdoutListener);
    process.stderr.on('data', stderrListener);

    proc.on('exit', function(code) {
      process.stdin.pause();
      process.stdout.removeListener('data', stdoutListener);
      process.stderr.removeListener('data', stderrListener);

      callback(err, out, code);
    });
  }

  return proc;
}

// A couple of global options
exec.quiet = false;
exec.safe = true;

// Wrapper function that handles exec being called with only one command or several
function wrapper(cmds, options, callback) {
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

  var complete = 0;

  // Iterate over list of cmds, calling each in order as long as all of them return without errors
  function iterate() {
    return exec(cmds[complete], function(err, out, code) {
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
    return iterate();
  } else {
    return exec(cmds, callback);
  }
}

module.exports = wrapper;
