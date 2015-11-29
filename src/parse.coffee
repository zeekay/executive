path       = require 'path'
shellQuote = require 'shell-quote'

{isString, isWin} = require './utils'

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
  if opts.shell? or shellRequired args
    console.log 'requiredShell'
    cmd = opts.shell ? '/bin/sh'
    args = ['-c', s]

  [cmd, args, env]

argsObject = (obj, opts, env) ->
  # Here args should be an object.
  cmd = obj.cmd

  # Merge any specified env vars.
  if obj.env
    for k,v of obj.env
      env[k] = v

  args = obj.args ? []

  [cmd, args, env]

module.exports = (args, opts = {}) ->
  # Extend from process.env
  env = Object.assign process.env, (opts.env ? {})

  # If args is a string, parse it into cmd/args/env.
  if isString args
    [cmd, args, env] = argsString args, opts, env
  else
    [cmd, args, env] = argsObject args, opts, env

  # Pass env to spawn
  opts.env = env

  # Hack to work around Windows oddities.
  if isWin
    cmd = path.normalize(cmd)
    args = ['/s', '/c', "\"#{cmd}\""].concat args
    cmd = 'cmd'
    opts.windowsVerbatimArguments = true

  [cmd, args, opts]
