import {spawn} from 'child_process'

import BufferStream     from './buffer-stream'
import parse            from './parse'
import {logError, once} from '../utils'

export default (cmd, opts, cb) ->
  [cmd, args, opts] = parse cmd, opts

  stderr = new BufferStream()
  stdout = new BufferStream()

  child = spawn cmd, args,
    cwd:      opts.cwd
    env:      opts.env
    stdio:    opts.stdio ? [0, 'pipe', 'pipe']
    detached: opts.detached
    uid:      opts.uid
    gid:      opts.gid

  child.setMaxListeners 0
  child.stdout.setEncoding opts.encoding ? 'utf8'
  child.stderr.setEncoding opts.encoding ? 'utf8'

  # Buffer stderr, stdout
  unless opts.interactive
    child.stdout.pipe stdout
    child.stderr.pipe stderr

  # Echo out as well
  unless opts.quiet
    child.stdout.pipe process.stdout
    child.stderr.pipe process.stderr

  done = once (err, status) ->
    stdout.destroy()
    stderr.destroy()
    child.kill()

    stdout = stdout.toString()
    stderr = stderr.toString()

    if err?
      err.cmd    = cmd
      err.args   = args
      err.stdout = stdout
      err.stderr = stderr
      err.status = status
      logError err unless opts.quiet

    cb err, stdout, stderr, status

  exit = once (status, signal) ->
    err = null

    unless status is 0
      err = new Error "Command failed, '#{cmd}' exited with status #{status}"
      err.signal = signal

    done err, status

  # Close fires after exit so we are relying on it for now.
  child.on 'close', exit
  # child.on 'exit', exit

  child.on 'error', done

  child
