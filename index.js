var child_process = require('child_process');

exports.exec = function(args, options, callback) {
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

  args = args.split(/\s+/g);
  cmd = args.shift();

  var proc = child_process.spawn(cmd, args),
      err  = '',
      out  = '';

  proc.stdout.on('data', function(data) {
    out += data;
    process.stdout.write(data);
  });

  proc.stderr.on('data', function(data) {
    err += data;
    process.stderr.write(data);
  });

  proc.on('exit', function(code) {
    callback(err, out, code);
  });
};
