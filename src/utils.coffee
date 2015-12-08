exports.error = (err) ->
  console.error "ExecutiveError: #{err.syscall} #{err.code}" if err.code is 'ENOENT'

exports.isArray = (a) ->
  Array.isArray a

exports.isFunction = (fn) ->
  typeof fn is 'function'

exports.isString = (s) ->
  typeof s is 'string'

exports.isWin = /^win/.test process.platform
