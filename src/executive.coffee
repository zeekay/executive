exec     = require './exec'
execSync = require './execSync'

{parallel, serial}              = require './flow'
{isArray, isFunction, isString} = require './utils'

module.exports = (cmds, opts, cb) ->
  # Split string of commands
  if isString cmds
    cmds = (cmds.split '\n').filter (c) -> c != ''

  # We also work with an array of commands
  unless isArray cmds
    cmds = [cmds]

  # Opts is optional
  if isFunction opts
    [cb, opts] = [opts, {}]

  opts ?= {}

  # Pick async control flow mechanism and executor, defaults to async serial
  executor = exec
  flow     = serial

  # execSync requested
  if opts.sync
    executor = execSync

  # Parallel execution requested
  if opts.parallel
    flow = parallel

  # Handle Node.js style callbacks
  if cb and isFunction cb
    return flow executor, cmds, opts, cb

  # Blocking exec
  if opts.sync
    out = ''
    err = ''

    return flow executor, cmds, opts, (err, stdout, stderr, status) ->
      return unless opts.syncThrows

      if opts.strict and status != 0
        throw err
      else if err? and not status?
        throw err

  # Promise API expected
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
