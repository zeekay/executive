{spawnSync} = require 'child_process'

parse   = require './parse'
logError = (require './utils').error

module.exports = (cmd, opts, cb) ->
  [cmd, args, opts] = parse cmd, opts

  opts.stdio ?= [0, 'pipe', 'pipe']

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

  if error?
    error.code   = status
    error.signal = signal
    error.pid    = pid
    error.stdout = stdout
    error.stderr = stderr
    logError error if error?

  cb error, stdout, stderr
