var child_process = require('child_process');

function parseShell(s) {
  if (!s) return;

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

function exec(args, options, callback) {
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
      throw new Error('No command specified.');
  }

  args = parseShell(args.join(' '));

  if (options.quiet) {
    // Do not echo to stdout/stderr
    proc = child_process.spawn(cmd, args, {env: env});

    proc.stdout.on('data', function(data) {
      out += data.toString();
    });

    proc.stderr.on('data', function(data) {
      err += data.toString();
    });

    proc.on('close', function(code) {
      callback(err, out, code);
    });

  } else {
    // Echo to stdout/stderr and handle stdin (unless interactive)
    proc = child_process.spawn(cmd, args, {env: env, stdio: [0, 1, 2]});
    proc.setMaxListeners(0);

    if (!options.interactive) {
      process.stdin.resume();

      var stdoutListener = function(data) {
        out += data.toString();
      };

      var stderrListener = function(data) {
        err += data.toString();
      };

      try {
        process.stdout.on('data', stdoutListener);
        process.stderr.on('data', stderrListener);
      } catch (error) {
        // well guess that won't work...
      }
    }

    proc.on('exit', function(code) {
      if (!options.interactive) {
        process.stdin.pause();
        process.stdout.removeListener('data', stdoutListener);
        process.stderr.removeListener('data', stderrListener);
      }

      callback(err, out, code);
    });
  }

  return proc;
}

// Wrapper function that handles exec being called with only one command or several
function wrapper(cmds, options, callback) {
  // If options is a function, assume we are called with only two arguments
  if (typeof options === 'function') {
    callback = options;
    options = {};
  }

  // Default options, callback
  if (!options) {
    options = {};
  }

  if (!callback) {
    callback = function() {};
  }

  var complete = 0;

  // Iterate over list of cmds, calling each in order as long as all of them return without errors
  function iterate() {
    return exec(cmds[complete], options, function(err, out, code) {
      if (options.safe && code !== 0) {
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
    return exec(cmds, options, callback);
  }
}

wrapper.quiet = function(cmds, options, callback) {
  if (typeof options === 'function') {
    callback = options;
    options = {};
  }

  if (!options) {
    options = {};
  }

  options.interactive = false;
  options.quiet = true;
  return wrapper(cmds, options, callback);
};

wrapper.interactive = function(cmds, options, callback) {
  if (typeof options === 'function') {
    callback = options;
    options = {};
  }

  if (!options) {
    options = {};
  }

  options.interactive = true;
  options.quiet = false;
  return wrapper(cmds, options, callback);
};

module.exports = wrapper;
