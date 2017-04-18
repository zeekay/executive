import {isArray, isFunction, isObject, isString} from 'es-is'

import exec               from './exec'
import execSync           from './execSync'
import {parallel, serial} from './flow'

# Save results from callback and return them synchronously
sync = (flow, executor, cmds, opts) ->
  out  = ''
  err  = ''
  code = 0

  # This happens synchronously
  return flow executor, cmds, opts, (err, stdout, stderr, status) ->
    return unless opts.syncThrows

    if opts.strict and status != 0
      throw err
    else if err? and not status?
      throw err

    out  = stdout
    err  = stderr
    code = status

  stdout: out, stderr: err, status: code

# Promise which resolves to exec results
promise = (flow, executor, cmds, opts) ->
  new Promise (resolve, reject) ->
    flow executor, cmds, opts, (err, stdout, stderr, status) ->
      if opts.strict and status != 0
        return reject err
      else if err? and not status?
        return reject err

      resolve
        stdout: stdout
        stderr: stderr
        status: status

export default (cmds, opts, cb) ->
  # Convert commands into an array if necessary
  unless isArray cmds

    # Split string of commands
    if isString cmds
      cmds = (cmds.split '\n').filter (c) -> c != ''

    # Create list of commands to execute if passed an object mapping
    if isObject cmds
      cmds = ({k: v} for k,v of cmds)

  # Passed only callback
  if isFunction opts
    [cb, opts] = [opts, {}]

  # Ensure opts exists
  opts ?= {}

  # Pick control flow and executor, defaults to async + serial
  executor = exec
  flow     = serial

  if opts.sync
    executor = execSync # Use sync
  if opts.parallel
    flow = parallel     # Use parallel

  # Async exec with errback-style callback
  return flow executor, cmds, opts, cb if cb and isFunction cb

  # Blocking exec
  return sync flow, executor execmds, opts if opts.sync

  # Async exec with Promise API expected
  promise flow, executor, cmds, opts
