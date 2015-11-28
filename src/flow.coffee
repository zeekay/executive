exports.serial = (fn, cmds, opts, cb) ->
  outAll = ''
  errAll = ''

  do (next = ->
    if cmds.length
      fn cmds.shift(), opts, (err, stdout, stderr) ->
        outAll += stdout
        errAll += stderr

        return cb err, outAll, errAll if err?

        next()
    else
      cb null, outAll, errAll)

exports.parallel = (fn, cmds, opts, cb) ->
  outAll = ''
  errAll = ''
  done = 0

  for cmd in cmds
    fn cmd, opts, (err, stdout, stderr) ->
      outAll += stdout
      errAll += stderr

      if ++done == cmds.length
        cb null, outAll, errAll
