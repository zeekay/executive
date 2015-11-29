Stream  = require 'stream'
{spawn} = require 'child_process'

parse   = require './parse'
{error} = require './utils'

class BufferStream extends Stream
  constructor: ->
    @buffer = ''
    @writable = true

  write: (data) ->
    @buffer += data

  end: (data) ->
    @write data if arguments.length
    @writable = false

  destroy: ->
    @writable = false

  toString: ->
    @buffer

module.exports = (cmd, opts, cb) ->
  [cmd, args, opts] = parse cmd, opts

  opts.stdio ?= [0, 'pipe', 'pipe']

  stderr = new BufferStream()
  stdout = new BufferStream()

  child = spawn cmd, args, opts

  child.setMaxListeners 0
  child.stdout.setEncoding 'utf8'
  child.stderr.setEncoding 'utf8'

  # Buffer stderr, stdout
  unless opts.interactive
    child.stdout.pipe stdout
    child.stderr.pipe stderr

  # Echo out as well
  unless opts.quiet
    child.stdout.pipe process.stdout
    child.stderr.pipe process.stderr

  done = (err) ->
    if err?
      err.stderr = stderr.toString()
      err.stdout = stdout.toString()
      error err

    child.kill()
    stderr.destroy()
    stdout.destroy()

    cb err, stdout.toString(), stderr.toString()

  child.on 'error', (err) ->
    err.cmd = cmd
    done err

  child.on 'close', (code) ->
    err = null

    unless code is 0
      err = new Error "#{cmd} exited with code #{code}"
      err.cmd  = "#{cmd} #{args.join ''}"
      err.code = code

    done err

  child
