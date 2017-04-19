import {isFunction, isPromise, isObject, isString} from 'es-is'

# Execute commands in parallel
export default parallel = (fn, cmds, opts, cb) ->
  outAll = ''
  errAll = ''
  errors = []
  todo   = cmds.length

  append = (res = {}) ->
    {stdout, stderr, status} = res

    if stdout?
      outAll += stdout
    if stderr?
      errAll += stderr

    if status?
      status
    else
      0

  done = (err, status = 0) ->
    if err?
      unless opts.quiet
        console.error err
        console.error err.stack
      errors.push err

    return if --todo

    if errors.length
      err = new Error 'Partial completion'
      err.errors = errors
      status = 1

    cb err, outAll, errAll, status

  while cmds.length
    cmd = cmds.shift()

    if isString cmd
      fn cmd, opts, (err, stdout, stderr, status) ->
        append stdout: stdout, stderr: stderr
        done err, status
    else if isFunction cmd
      try
        val = cmd()
        if isPromise val
          cmds.push val
        else if isString val
          cmds.push val
        else
          append val
          done null, 0
      catch err
        done err

    else if isPromise cmd
      cmd
        .then  (val) ->
          append val
          done null, 0
        .catch (err) ->
          done err

  return
