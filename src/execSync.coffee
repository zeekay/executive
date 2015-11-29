{spawnSync} = require 'child_process'

parse = require './parse'

{logError} = require './utils'

module.exports = (cmd, opts, cb) ->
  [cmd, args, opts] = parse cmd, opts

  opts.stdio ?= [0, 'pipe', 'pipe']
  opts.encoding ?= 'utf-8'

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

  unless error? or status != 0
    error = new Error "Command failed, '#{cmd}' exited with status #{status}"

  if error?
    error.status = status
    error.pid    = pid
    error.signal = signal
    error.stderr = stderr
    error.stdout = stdout
    logError error unless opts.quiet

  cb error, stdout, stderr, status

  status: status
  stderr: stderr
  stdout: stdout
  error:  error
