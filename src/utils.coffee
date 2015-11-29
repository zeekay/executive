exports.logError = (err) ->
  if (err.code is 'ENOENT') and /^spawn/.test err.syscall
    console.error "Error: #{err.code}, #{err.syscall}"
    console.error "Make sure '#{err.cmd}' exists and is executable."

exports.isArray = (a) ->
  Array.isArray a

exports.isFunction = (fn) ->
  typeof fn is 'function'

exports.isString = (s) ->
  typeof s is 'string'

exports.isWin = /^win/.test process.platform

exports.once = (fn) ->
  ran    = false
  result = null
  ->
    return result if ran
    ran = true
    result = fn.apply @, arguments
    fn = null
    result
