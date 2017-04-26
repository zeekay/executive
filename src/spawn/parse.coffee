import fs         from 'fs'
import path       from 'path'
import shellQuote from 'shell-quote'
import {isString, isObject} from 'es-is'

import builtins   from './shell-builtins'

isWin = /^win/.test process.platform


# Convert objects in shell-quote results back into string arguments
unShellQuote = (args) ->
  args_ = []
  for a in args
    if isString a
      args_.push a
    else
      if a.op == 'glob'
        args_.push a.pattern
      else
        args_.push a.op
  args_


# Parse string containing shell command
parseShell = (s, env) ->
  args = shellQuote.parse s, env

  # Grab command (usually first argument)
  cmd  = args.shift()

  # Process any env vars that might be in front of our command
  while ~cmd.indexOf '='
    # Found env var i.e., FOO=1 echo $FOO
    foundEnv = true

    # Update env object
    [k,v]    = cmd.split '=', 2
    env[k]   = v

    # Grab next arg, see if it's a command
    cmd = args.shift()

  # Re-parse if env var discovered
  if foundEnv
    return parseShell s, env

  [cmd, args, env]


# Parse cmd, args, env from string
parseString = (s, opts) ->
  env = Object.assign {}, process.env, opts.env
  [cmd, args, env] = parseShell s, env


# Parse cmd, args, env from object
parseObject = (obj, opts) ->
  cmd  = obj.cmd
  args = obj.args ? []
  env  = Object.assign {}, process.env, opts.env, obj.env
  [cmd, args, env]


# Check for any operators or glob patterns
shellRequired = (cmd, args) ->
  return true if builtins[cmd]

  for arg in args
    unless isString arg
      return true
  false


# Couple of hacks to ensure commands run smoothly on Windows
winHacks = (cmd, args) ->
  cmd     = path.normalize cmd
  cmdfile = cmd + '.cmd'

  # Use .cmd version of command if it exists
  cmd = cmdfile if fs.existsSync cmdfile

  # Setup arguments for cmd.exe and use that as executable
  args = ['/c', cmd].concat args
  cmd  = 'cmd.exe'

  [cmd, args]


# Parse cmd, args, env from string or object
export default parse = (cmdArgs, opts = {}) ->
  # Handle string, object style cmd+args
  if isString cmdArgs
    [cmd, args, env] = parseString cmdArgs, opts
  else if isObject cmdArgs
    [cmd, args, env] = parseObject cmdArgs, opts
  else
    throw new Error "Unable to parse command '#{cmdArgs}'"

  # Detect if shell is required and stringify args correctly
  if shellRequired cmd, args
    opts.shell ?= true
    args        = unShellQuote args

  # Apply hacks to work around Windows oddities if necessary
  [cmd, args] = winHacks cmd, args if isWin

  # Our normalized cmd, args and opts
  [cmd, args, opts]
