var childProcess = require('child_process'),
    isWin         = /^win/.test(process.platform),
    path          = require('path'),
    Stream        = require('stream'),
    shellQuote    = require('shell-quote');

function error(err) {
    if (err.code === 'ENOENT') {
      console.error('ExecutiveError: ' + err.syscall + ' ' + err.code)
    }
}

function bufferedExec(cmd, args, opts, callback) {
  var err = '',
      out = '';

  if (args == null)
    args = [];

  // stream to capture stdout
  var stdout = new Stream();
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
  var stderr = new Stream();
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

  var child = childProcess.spawn(cmd, args, opts);

  child.on('error', function(err) {
    err.cmd = cmd;
    error(err)
    callback(err);
  })

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
      _err = new Error(cmd + ' exited with code ' + code);
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

  var child = childProcess.spawn(cmd, args, opts);

  child.on('error', function(err) {
    err.cmd = cmd;
    error(err)
    callback(err);
  })

  child.setMaxListeners(0);

  child.on('exit', function(code) {
    callback(null, null, null, code);
  });

  return child;
}

// Do not echo to stdout/stderr
function quietExec(cmd, args, opts, callback) {
  var err = '',
      out = '';

  if (args == null)
    args = [];

  var child = childProcess.spawn(cmd, args, opts);

  child.on('error', function(err) {
    err.cmd = cmd;
    error(err)
    callback(err);
  })

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
      _err = new Error(cmd + ' exited with code ' + code);
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
  var env = {}, e, cmd;

  // Copy enviromental variables from process.env.
  for (e in process.env) env[e] = process.env[e];

  // If args is a string, parse it into cmd/args/env.
  if (typeof args === 'string') {
    args = shellQuote.parse(args);

    while (cmd = args.shift()) {
      // Check if this is an enviromental variable
      if (cmd.indexOf('=') == -1) {
        break;
      }

      // Save env variable
      e = cmd.split('=', 2);
      env[e[0]] = e[1];
    }
  } else {
    // Here args should be an object.
    cmd = args.cmd;

    // Merge any specified env vars.
    if (args.env) {
      for (e in args.env) env[e] = args.env[e];
    }

    if (args.args) {
      args = args.args;
    } else {
      args = [];
    }
  }

  // Pass env to spawn
  opts.env = env;

  // Hack to work around Windows oddities.
  if(isWin) {
    cmd = path.normalize(cmd);
    args = ['/s', '/c', '"' + cmd + '"'].concat(args);
    cmd = 'cmd';
    opts.windowsVerbatimArguments = true;
  }

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

  if (!callback) {
    callback = function() {};
  }

  var complete = 0,
      outBuf = '',
      errBuf = '';

  // Iterate over list of cmds, calling each in order as long as all of them return without errors
  function iterate() {
    return exec(cmds[complete], opts, function(err, stdout, stderr, code) {
      if ((err != null) || (code !== 0)) {
        return callback(err, outBuf, errBuf, code);
      }

      if ((stderr != null) && (stderr !== ''))
        errBuf += stderr;

      if ((stdout != null) && (stdout !== ''))
        outBuf += stdout;

      complete++;

      if (complete === cmds.length) {
        callback(err, outBuf, errBuf, code);
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

module.exports = wrapper;
