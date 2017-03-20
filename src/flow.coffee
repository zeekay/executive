import {isString, isPromise} from 'es-is'

export serial = (fn, cmds, opts, cb) ->
  errAll     = ''
  outAll     = ''
  lastStatus = null

  do (next = ->
    if cmds.length
      cmd = cmds.shift()
      if isString cmd
        fn cmd, opts, (err, stdout, stderr, status) ->
          outAll    += stdout
          errAll    += stderr
          lastStatus = status

          if opts.strict && err?
            cb err, outAll, errAll, lastStatus
          else
            next()
      else if isPromise
        cmd.then  (val) ->  next()
           .catch (err) ->  cb err, outAll, errAll, 1
      else
        return cb new Error "Not a valid command: #{cmd.toString()}"

    else
      cb null, outAll, errAll, lastStatus)

export parallel = (fn, cmds, opts, cb) ->
  outAll = ''
  errAll = ''
  done   = 0

  next = (status = 0) ->
    if ++done == cmds.length
        cb null, outAll, errAll, status

  for cmd in cmds
    if isString cmd
      fn cmd, opts, (err, stdout, stderr, status) ->
        outAll += stdout
        errAll += stderr

        next status
    else if isPromise
      cmd.then  (val) -> next 0
         .catch (err) -> (console.error err) and next 1
