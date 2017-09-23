import {
  isArray
  isFunction
  isObject
  isPromise
  isString
} from 'es-is'

# Execute commands in parallel
export default parallel = (fn, cmds, opts, cb) ->
  outAll = ''
  errAll = ''
  errors = []
  todo   = cmds.length

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
      status
    else
      0

    if key?
      object[key] =
        error:  error
        stdout: stdout
        stderr: stderr
        status: status

  done = (err, status = 0) ->
    if err?
      unless opts.quiet
        console.error err.toString()
      errors.push err

    return if --todo

    if errors.length
      err = new Error 'Partial completion'
      err.errors = errors
      status = 1

    cb err, outAll, errAll, status, object

  while cmds.length
    cmd = cmds.shift()
    do (cmd) ->
      [key, cmd] = cmd if isArray cmd

      if isString cmd
        cmd = cmd.replace /\\/g, '\\\\'
        fn cmd, opts, (err, stdout, stderr, status) ->
          append key,
            error:  err
            stdout: stdout
            stderr: stderr
            status: status
          done err, status

      else if isFunction cmd
        try
          val = cmd()
          if isPromise val
            cmds.push val
          else if isString val
            cmds.push val
          else
            append key, val
            done null, 0
        catch err
          done err

      else if isPromise cmd
        cmd
          .then (val) ->
            append key, val
            done null, 0
          .catch (err) ->
            done err

  return
