path       = require 'path'
shellQuote = require 'shell-quote'

{isString, isWin} = require './utils'

argsString = (s, env) ->
  args = shellQuote.parse s

  while cmd = args.shift()
    # Check if this is an enviromental variable
    break if cmd.indexOf('=') is -1

    # Update env
    [k,v] = cmd.split '=', 2

    env[k] = v

  [cmd, args, env]

argsObject = (obj, env) ->
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
    [cmd, args, env] = argsString args, env
  else
    [cmd, args, env] = argsObject args, env

  # Pass env to spawn
  opts.env = env

  # Hack to work around Windows oddities.
  if isWin
    cmd = path.normalize(cmd)
    args = ['/s', '/c', "\"#{cmd}\""].concat args
    cmd = 'cmd'
    opts.windowsVerbatimArguments = true

  [cmd, args, opts]
