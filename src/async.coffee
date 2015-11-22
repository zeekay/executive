childProcess = require 'child_process'
isWin        = /^win/.test process.platform
path         = require 'path'
Stream       = require 'stream'
shellQuote   = require 'shell-quote'

error = (err) ->
  console.error "ExecutiveError: #{err.syscall} #{err.code}" if err.code is 'ENOENT'

spawn = (cmd, args, opts) ->
  # need to mock out child like object
  return childProcess.spawnSync(cmd, args, opts) if opts.sync
  childProcess.spawn cmd, args, opts

bufferedExec = (cmd, args, opts, cb) ->
  err = ''
  out = ''
  args = [] unless args?

  # stream to capture stdout
  stdout = new Stream()
  stdout.writable = true
  stdout.write = (data) ->
    out += data

  stdout.end = (data) ->
    stdout.write data if arguments.length
    stdout.writable = false

  stdout.destroy = ->
    stdout.writable = false

  # stream to capture stderr
  stderr = new Stream()
  stderr.writable = true
  stderr.write = (data) ->
    err += data

  stderr.end = (data) ->
    stderr.write data if arguments.length
    stderr.writable = false

  stderr.destroy = ->
    stderr.writable = false

  opts.stdio = [0, 'pipe', 'pipe']

  child = spawn(cmd, args, opts)
  child.on 'error', (err) ->
    err.cmd = cmd
    error err
    cb err

  child.setMaxListeners 0
  child.stdout.setEncoding "utf8"
  child.stderr.setEncoding "utf8"
  child.stdout.pipe stdout
  child.stderr.pipe stderr
  child.stdout.pipe process.stdout
  child.stderr.pipe process.stderr
  child.on "close", (code) ->
    _err = null
    if code isnt 0
      _err = new Error(cmd + " exited with code " + code)
      _err.cmd = cmd + " " + args.join(" ")
      _err.code = code
      _err.stderr = err
      _err.stdout = out
    stdout.destroy()
    stderr.destroy()
    cb _err, out, err, code
    return

  child

interactiveExec = (cmd, args, opts, cb) ->
  opts.stdio = "inherit"
  child = spawn(cmd, args, opts)
  child.on "error", (err) ->
    err.cmd = cmd
    error err
    cb err
    return

  child.setMaxListeners 0
  child.on "exit", (code) ->
    cb null, null, null, code
    return

  child

# Do not echo to stdout/stderr
quietExec = (cmd, args, opts, cb) ->
  err = ""
  out = ""
  args = []  unless args?
  child = spawn(cmd, args, opts)
  child.on "error", (err) ->
    err.cmd = cmd
    error err
    cb err
    return

  child.setMaxListeners 0
  child.stdout.setEncoding "utf8"
  child.stderr.setEncoding "utf8"
  child.stdout.on "data", (data) ->
    out += data
    return

  child.stderr.on "data", (data) ->
    err += data
    return

  child.on "close", (code) ->
    _err = null
    if code isnt 0
      _err = new Error(cmd + " exited with code " + code)
      _err.cmd = cmd + " " + args.join(" ")
      _err.code = code
      _err.stderr = err
      _err.stdout = out
    cb _err, out, err, code
    return

  child

exec = (args, opts, cb) ->
  env = {}
  e = undefined
  cmd = undefined

  # Copy enviromental variables from process.env.
  for e of process.env
    env[e] = process.env[e]

  # If args is a string, parse it into cmd/args/env.
  if typeof args is "string"
    args = shellQuote.parse(args)
    while cmd = args.shift()

      # Check if this is an enviromental variable
      break  if cmd.indexOf("=") is -1

      # Save env variable
      e = cmd.split("=", 2)
      env[e[0]] = e[1]
  else

    # Here args should be an object.
    cmd = args.cmd

    # Merge any specified env vars.
    if args.env
      for e of args.env
        env[e] = args.env[e]
    if args.args
      args = args.args
    else
      args = []

  # Pass env to spawn
  opts.env = env

  # Hack to work around Windows oddities.
  if isWin
    cmd = path.normalize(cmd)
    args = [
      "/s"
      "/c"
      "\"" + cmd + "\""
    ].concat(args)
    cmd = "cmd"
    opts.windowsVerbatimArguments = true
  return quietExec(cmd, args, opts, cb)  if opts.quiet
  return interactiveExec(cmd, args, opts, cb)  if opts.interactive
  bufferedExec cmd, args, opts, cb

# Wrapper function that handles exec being called with only one command or several
wrapper = (cmds, opts, cb) ->
  # If opts is a function, assume we are called with only two arguments
  if typeof opts is "function"
    cb = opts
    opts = {}

  # Default opts, callback
  opts = {} unless opts
  cb   = -> unless cb

  complete = 0
  outBuf   = ''
  errBuf   = ''

  # Iterate over list of cmds, calling each in order as long as all of them return without errors
  iterate = ->
    exec cmds[complete], opts, (err, stdout, stderr, code) ->
      return cb(err, outBuf, errBuf, code)  if (err?) or (code isnt 0)
      errBuf += stderr  if (stderr?) and (stderr isnt '')
      outBuf += stdout  if (stdout?) and (stdout isnt '')
      complete++
      if complete is cmds.length
        cb err, outBuf, errBuf, code
      else
        iterate()
      return

  # If we are passed an array of commands, call each in serial, otherwise exec immediately.
  if Array.isArray(cmds)
    iterate()
  else
    exec cmds, opts, callback

wrapper.quiet = (cmds, opts, callback) ->
  if typeof opts is "function"
    callback = opts
    opts = {}
  opts = {}  unless opts
  opts.interactive = false
  opts.quiet = true
  wrapper cmds, opts, callback

wrapper.interactive = (cmds, opts, callback) ->
  if typeof opts is "function"
    callback = opts
    opts = {}
  opts = {}  unless opts
  opts.interactive = true
  opts.quiet = false
  wrapper cmds, opts, callback

wrapper.sync = (cmds, opts, callback) ->
  if typeof opts is "function"
    callback = opts
    opts = {}
  opts = {}  unless opts
  opts.sync = true
  wrapper cmds, opts, callback

wrapper.quietSync = (cmds, opts, callback) ->
  if typeof opts is "function"
    callback = opts
    opts = {}
  opts = {}  unless opts
  opts.sync = true
  wrapper.quiet cmds, opts, callback

wrapper.interactiveSync = (cmds, opts, callback) ->
  if typeof opts is "function"
    callback = opts
    opts = {}
  opts = {}  unless opts
  opts.sync = true
  wrapper.interactive cmds, opts, callback

wrapper.bufferedExec    = bufferedExec
wrapper.quietExec       = quietExec
wrapper.interactiveExec = interactiveExec
wrapper.version         = require("./package").version

module.exports = wrapper
