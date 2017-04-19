import {spawnSync} from 'child_process'

import parse      from './parse'
import {logError} from '../utils'

export default (cmd, opts, cb) ->
  [cmd, args, opts] = parse cmd, opts

  {
    pid
    output
    stdout
    stderr
    status
    signal
    error
  } = spawnSync cmd, args,
    cwd:        opts.cwd
    input:      opts.input
    stdio:      opts.stdio ? [0, 'pipe', 'pipe']
    env:        opts.env
    uid:        opts.uid
    gid:        opts.gid
    timeout:    opts.timeout
    killSignal: opts.killSignal
    maxBuffer:  opts.maxBuffer
    encoding:   opts.encoding ? 'utf8'

  opts

  unless opts.quiet
    process.stdout.write stdout
    process.stderr.write stderr

  if not error? and status != 0
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
