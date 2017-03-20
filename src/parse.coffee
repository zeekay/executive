import fs         from 'fs'
import path       from 'path'
import shellQuote from 'shell-quote'
import {isString} from 'es-is'

import {isWin} from './utils'

# Check for any operators/glob patterns
shellRequired = (args) ->
  for arg in args
    unless isString arg
      return true
  false

argsString = (s, opts, env) ->
  args = shellQuote.parse s

  # Parse out enviromental variables
  while cmd = args.shift()
    break if (cmd.indexOf '=') is -1
    [k,v] = cmd.split '=', 2
    env[k] = v

  # Check for any glob or operators
  unless isWin
    if opts.shell? or shellRequired args
      cmd = opts.shell ? '/bin/sh'
      args = ['-c', s]

  [cmd, args, env]

argsObject = (obj, opts, env) ->
  # Here args should be an object.
  cmd = obj.cmd

  # Merge any specified env vars.
  env = Object.assign env, obj.env ? {}

  args = obj.args ? []

  [cmd, args, env]

export default (args, opts = {}) ->
  # Extend from process.env
  env = Object.assign process.env, (opts.env ? {})

  # If args is a string, parse it into cmd/args/env.
  if isString args
    [cmd, args, env] = argsString args, opts, env
  else
    [cmd, args, env] = argsObject args, opts, env

  # Pass env to spawn
  opts.env = env

  # Hacks to work around Windows oddities.
  if isWin
    # Normalize path for Windows
    cmd = path.normalize cmd

    # Check for a .cmd version and use it if it exists
    if fs.existsSync cmd_ = cmd + '.cmd'
      cmd = cmd_

    # Setup arguments for cmd.exe and use that as executable
    args = ['/c', cmd].concat args
    cmd = 'cmd.exe'

  [cmd, args, opts]
