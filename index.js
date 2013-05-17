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

function bufferedExec(cmd, args, env, callback) {
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

  var child = child_process.spawn(cmd, args, {env: env, stdio: [0, 'pipe', 'pipe']});

  child.setMaxListeners(0);
  child.stdout.setEncoding('utf8');
  child.stderr.setEncoding('utf8');

  child.stdout.pipe(stdout);
  child.stderr.pipe(stderr);
  child.stdout.pipe(process.stdout);
  child.stderr.pipe(process.stderr);

  child.on('close', function(code) {
    stdout.destroy();
    stderr.destroy();
    callback(err, out, code);
  });

  return child;
}

function interactiveExec(cmd, args, env, callback) {
  var child = child_process.spawn(cmd, args, {env: env, stdio: [0, 1, 2]});

  child.setMaxListeners(0);

  child.on('exit', function(code) {
    callback(null, null, code);
  });

  return child;
}

// Do not echo to stdout/stderr
function quietExec(cmd, args, env, callback) {
  var child = child_process.spawn(cmd, args, {env: env}),
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
    callback(err, out, code);
  });

  return child;
}

function exec(args, options, callback) {
  var env = {}, e, cmd, arg;

  // Copy enviromental variables from process.env.
  for (e in process.env) env[e] = process.env[e];

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

  if (options.quiet)
    return quietExec(cmd, args, env, callback);

  if (options.interactive)
    return interactiveExec(cmd, args, env, callback);

  return bufferedExec(cmd, args, env, callback);
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

  if (typeof options.safe === 'undefined') {
    options.safe = true;
  }

  if (!callback) {
    callback = function() {};
  }

  var complete = 0,
      outBuf = '',
      errBuf = '';

  // Iterate over list of cmds, calling each in order as long as all of them return without errors
  function iterate() {
    return exec(cmds[complete], options, function(err, out, code) {
      errBuf += err;
      outBuf += out;

      if (options.safe && code !== 0) {
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

wrapper.bufferedExec = bufferedExec
wrapper.quietExec = quietExec
wrapper.interactiveExec = interactiveExec

module.exports = wrapper;
