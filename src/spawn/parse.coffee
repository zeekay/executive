import fs         from 'fs'
import path       from 'path'
import shellQuote from 'shell-quote'
import {isString} from 'es-is'


isWin = /^win/.test process.platform


# Couple of hacks to ensure commands run smoothly on Windows
winHacks = (cmd, args) ->
  # Normalize path for Windows
  cmd = path.normalize cmd

  # Check for a .cmd version and use it if it exists
  if fs.existsSync file = cmd + '.cmd'
    cmd = file

  # Setup arguments for cmd.exe and use that as executable
  args = ['/c', cmd].concat args
  cmd = 'cmd.exe'
  [cmd, args]


# Check for any operators or glob patterns
shellRequired = (args) ->
  for arg in args
    unless isString arg
      return true
  false


# Parse cmd, args, env from string
string = (s, opts) ->
  args = shellQuote.parse s
  env  = {}

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


# Parse cmd, args, env from object
object = (obj, opts) ->
  cmd  = obj.cmd
  args = obj.args ? []
  [cmd, args, obj.env]


# Parse cmd, args, env from string or object
export default (cmd, opts = {}) ->
  if isString cmd
    [cmd, args, env] = string cmd, opts
  else if isObject cmd
    [cmd, args, env] = object cmd, opts
  else
    throw new Error "Unable to parse cmd = #{cmd}"

  # Use process.env by default, but allow opts.env and parsed env to override
  opts.env = Object.assign {}, process.env, opts.env, env

  # Apply hacks to work around Windows oddities if necessary
  [cmd, args] = winHacks cmd, args if isWin

  # Our normalized cmd, args and opts
  [cmd, args, opts]
