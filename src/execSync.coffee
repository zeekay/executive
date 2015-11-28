{spawnSync} = require 'child_process'

parse       = require './parse'
{error}     = require './utils'

module.exports = (cmd, opts, cb) ->
  [cmd, args, opts] = parse cmd, opts

  opts.stdio = [0, 'pipe', 'pipe']

  {
    pid
    output
    stdout
    stderr
    status
    signal
    error
  } = spawnSync cmd, args, opts

  unless opts.quiet
    process.stdout.write stdout
    process.stderr.write stderr

  if err?
    error err if err?
    err.code   = status
    err.signal = signal
    err.pid    = pid

  cb err, stdout, stderr
