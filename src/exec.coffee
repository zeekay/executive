Stream    = require 'stream'
readPkgUp = require 'read-pkg-up'
{spawn}   = require 'child_process'

parse = require './parse'
{logError, once} = require './utils'

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

  child.on 'close', exit
  child.on 'exit',  exit
  child.on 'error', done

  child
