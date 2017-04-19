import {
  isArray
  isFunction
  isObject
  isPromise
  isString
} from 'es-is'


# Execute commands in serial
export default serial = (fn, cmds, opts, cb) ->
  errAll     = ''
  outAll     = ''
  lastStatus = null

  if cmds.length and isArray cmds[0]
    object = {}
  else
    object = null

  append = (key, res = {}) ->
    {error, stdout, stderr, status} = res

    if stdout?
      outAll += stdout

    if stderr?
      errAll += stderr

    if status?
      lastStatus = status
    else
      lastStatus = 0

    if key?
      object[key] =
        error:  error
        stdout: stdout
        stderr: stderr
        status: status

  do next = ->
    unless cmds.length
      return cb null, outAll, errAll, lastStatus, object

    cmd = cmds.shift()

    [key, cmd] = cmd if isArray cmd

    if isString cmd
      fn cmd, opts, (err, stdout, stderr, status) ->
        append key,
          error:  err
          stdout: stdout
          stderr: stderr
          status: status

        if opts.strict and err?
          cb err, outAll, errAll, lastStatus, object
        else
          next()

    else if isPromise cmd
      cmd
        .then (val) ->
          append key, val
          next()
        .catch (err) ->
          cb err, outAll, errAll, 1, object

    else if isFunction cmd
      try
        val = cmd()
        if (isPromise val) or (isString val)
          cmds.unshift val
        else
          append key, val
        next()
      catch err
        cb err, outAll, errAll, 1, object
    else
      cb new Error "Not a valid command: #{cmd.toString()}"
