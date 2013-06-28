var child_process = require('child_process'),
    Stream = require('stream');

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

function bufferedExec(cmd, args, opts, callback) {
  var err = '',
      out = '';

  // stream to capture stdout
  stdout = new Stream();
  stdout.writable = true;

  stdout.write = function(data) {
    out += data;
  };

  stdout.end = function(data) {
    if (arguments.length) stdout.write(data);
    stdout.writable = false;
  };

  stdout.destroy = function() {
    stdout.writable = false;
  };

  // stream to capture stderr
  stderr = new Stream();
  stderr.writable = true;

  stderr.write = function(data) {
    err += data;
  };

  stderr.end = function(data) {
    if (arguments.length) stderr.write(data);
    stderr.writable = false;
  };

  stderr.destroy = function() {
    stderr.writable = false;
  };

  opts.stdio = [0, 'pipe', 'pipe']
  var child  = child_process.spawn(cmd, args, opts);

  child.setMaxListeners(0);
  child.stdout.setEncoding('utf8');
  child.stderr.setEncoding('utf8');

  child.stdout.pipe(stdout);
  child.stderr.pipe(stderr);
  child.stdout.pipe(process.stdout);
  child.stderr.pipe(process.stderr);

  child.on('close', function(code) {
    var _err = null;

    if (code !== 0) {
      _err = new Error(cmd + 'exited with code ' + code);
      _err.cmd    = cmd + ' ' + args.join(' ')
      _err.code   = code
      _err.stderr = err
      _err.stdout = out
    }

    stdout.destroy();
    stderr.destroy();

    callback(_err, out, err, code);
  });

  return child;
}

function interactiveExec(cmd, args, opts, callback) {
  opts.stdio = 'inherit'
  var child  = child_process.spawn(cmd, args, opts);

  child.setMaxListeners(0);

  child.on('exit', function(code) {
    callback(null, null, null, code);
  });

  return child;
}

// Do not echo to stdout/stderr
function quietExec(cmd, args, opts, callback) {
  var child = child_process.spawn(cmd, args, opts),
      err = '',
      out = '';

  child.setMaxListeners(0);
  child.stdout.setEncoding('utf8');
  child.stderr.setEncoding('utf8');

  child.stdout.on('data', function(data) {
    out += data;
  });

  child.stderr.on('data', function(data) {
    err += data;
  });

  child.on('close', function(code) {
    var _err = null;

    if (code !== 0) {
      _err = new Error(cmd + 'exited with code ' + code);
      _err.cmd    = cmd + ' ' + args.join(' ')
      _err.code   = code
      _err.stderr = err
      _err.stdout = out
    }

    callback(_err, out, err, code);
  });

  return child;
}

function exec(args, opts, callback) {
  var env = {}, e, cmd, arg;

  // Copy enviromental variables from process.env.
  for (e in process.env) env[e] = process.env[e];

  // If args is a string, parse it into cmd/args/env.
  if (typeof args === 'string') {
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
      e = cmd.split('=');

      if (e.length != 2)
        throw new Error('Invalid enviromental variable specified.');

      env[e[0]] = e[1];

      if (args.length === 0)
        throw new Error('No command specified.');
    }

    args = parseShell(args.join(' '));
  }
  // Here args should be an object.
  else {
    cmd = args.cmd;

    // Merge any specified env vars.
    if (args.env) {
      for (e in args.env) env[e] = args.env[e];
    }

    if (args.args) {
      args = args.args;
    }
    else {
      args = [];
    }
  }

  // Pass env to spawn
  opts.env = env;

  if (opts.quiet)
    return quietExec(cmd, args, opts, callback);

  if (opts.interactive)
    return interactiveExec(cmd, args, opts, callback);

  return bufferedExec(cmd, args, opts, callback);
}

// Wrapper function that handles exec being called with only one command or several
function wrapper(cmds, opts, callback) {
  // If opts is a function, assume we are called with only two arguments
  if (typeof opts === 'function') {
    callback = opts;
    opts = {};
  }

  // Default opts, callback
  if (!opts) {
    opts = {};
  }

  if (typeof opts.safe === 'undefined') {
    opts.safe = true;
  }

  if (!callback) {
    callback = function() {};
  }

  var complete = 0,
      outBuf = '',
      errBuf = '';

  // Iterate over list of cmds, calling each in order as long as all of them return without errors
  function iterate() {
    return exec(cmds[complete], opts, function(err, out, code) {
      errBuf += err;
      outBuf += out;

      if (opts.safe && code !== 0) {
        return callback(errBuf, outBuf, code);
      }

      complete++;
      if (complete === cmds.length) {
        callback(errBuf, outBuf, code);
      } else {
        iterate();
      }
    });
  }

  // If we are passed an array of commands, call each in serial, otherwise exec immediately.
  if (Array.isArray(cmds)) {
    return iterate();
  } else {
    return exec(cmds, opts, callback);
  }
}

wrapper.quiet = function(cmds, opts, callback) {
  if (typeof opts === 'function') {
    callback = opts;
    opts = {};
  }

  if (!opts) {
    opts = {};
  }

  opts.interactive = false;
  opts.quiet = true;
  return wrapper(cmds, opts, callback);
};

wrapper.interactive = function(cmds, opts, callback) {
  if (typeof opts === 'function') {
    callback = opts;
    opts = {};
  }

  if (!opts) {
    opts = {};
  }

  opts.interactive = true;
  opts.quiet = false;
  return wrapper(cmds, opts, callback);
};

wrapper.bufferedExec = bufferedExec;
wrapper.quietExec = quietExec;
wrapper.interactiveExec = interactiveExec;
wrapper.parseShell = parseShell;

module.exports = wrapper;
