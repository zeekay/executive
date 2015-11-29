exports.serial = (fn, cmds, opts, cb) ->
  outAll = ''
  errAll = ''
  lastStatus = null

  do (next = ->
    if cmds.length
      fn cmds.shift(), opts, (err, stdout, stderr, status) ->
        outAll += stdout
        errAll += stderr
        lastStatus = status

        return (cb err, outAll, errAll, lastStatus) if err?

        next()
    else
      cb null, outAll, errAll, lastStatus)

exports.parallel = (fn, cmds, opts, cb) ->
  outAll = ''
  errAll = ''
  done = 0

  for cmd in cmds
    fn cmd, opts, (err, stdout, stderr, status) ->
      outAll += stdout
      errAll += stderr

      if ++done == cmds.length
        cb null, outAll, errAll, status
