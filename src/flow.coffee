import {isFunction, isPromise, isObject, isString} from 'es-is'


# Execute commands in serial
serial = (fn, cmds, opts, cb) ->
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

# Execute commands in parallel
parallel = (fn, cmds, opts, cb) ->
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


# Execute array of commands, with serial execution by default
array = (fn, arr, opts, cb) ->
  if opts.parallel
    parallel fn, arr, opts, cb
  else
    serial fn, arr, opts, cb


# Execute string representing commands
string = (fn, str, opts, cb) ->
  arr = (str.split '\n').filter (c) -> c != ''
  array fn, arr, opts, cb


# Execute object of commands
object = (fn, obj, opts, cb) ->
  ret  = Object.assign {}, obj
  cmds = ([k,v] for k,v of obj)

  # Synchronous command execution, neither parallel nor serial matter
  if opts.sync
    for [k,cmd] in cmds
      serial fn, cmd, opts, ()

    Promise.all (serial fn, cmd, opts, cb) for k,cmd of cmds
      .then (results) ->

  else
    done = (k) ->
      (res = {}) ->
        ret[k] = res

    do next = ->
      unless cmds.length
        serial fn, cmd, opts, done


# Execute commands using either serial or parallel control flow and return
# result to cb
export default flow = (executor, cmds, opts, cb) ->
  if isString cmds
    string executor, cmds, opts, cb
  if isObject cmds
    object executor, cmds, opts, cb
  if isArray cmds
    array executor,  cmds, opts, cb

  throw new Error "Unable to return results for cmds = #{JSON.stringify cmds}"
