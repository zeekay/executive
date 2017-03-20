export isWin = /^win/.test process.platform

export logError = (err) ->
  if (err.code is 'ENOENT') and /^spawn/.test err.syscall
    console.error "Error: #{err.code}, #{err.syscall}"
    console.error "Make sure '#{err.cmd}' exists and is executable."

export once = (fn) ->
  ran    = false
  result = null
  ->
    return result if ran
    ran = true
    result = fn.apply @, arguments
    fn = null
    result
