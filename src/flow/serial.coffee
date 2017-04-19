import {isFunction, isPromise, isObject, isString} from 'es-is'


# Execute commands in serial
export default serial = (fn, cmds, opts, cb) ->
  errAll     = ''
  outAll     = ''
  lastStatus = null

  append = (res = {}) ->
    {stdout, stderr, status} = res

    if stdout?
      outAll += stdout
    if stderr?
      errAll += stderr

    if status?
      lastStatus = status
    else
      lastStatus = 0

  do next = ->
    unless cmds.length
      return cb null, outAll, errAll, lastStatus

    cmd = cmds.shift()

    if isString cmd
      fn cmd, opts, (err, stdout, stderr, status) ->
        outAll    += stdout
        errAll    += stderr
        lastStatus = status

        if opts.strict and err?
          cb err, outAll, errAll, lastStatus
        else
          next()

    else if isPromise cmd
      cmd
        .then (val) ->
          append val
          next()
        .catch (err) ->
          cb err, outAll, errAll, 1

    else if isFunction cmd
      try
        val = cmd()
        if (isPromise val) or (isString val)
          cmds.unshift val
        else
          append val
        next()
      catch err
        cb err, outAll, errAll, 1

    else
      cb new Error "Not a valid command: #{cmd.toString()}"
