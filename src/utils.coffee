# Log error
export logError = (err) ->
  if (err.code is 'ENOENT') and /^spawn/.test err.syscall
    console.error "Error: #{err.code}, #{err.syscall}"
    console.error "Make sure '#{err.cmd}' exists and is executable."


# Run command exactly once
export once = (fn) ->
  ran    = false
  result = null
  ->
    return result if ran
    ran    = true
    result = fn.apply @, arguments
    fn     = null
    result


# Merge stdout, stderr, status into results object
export mergeResult = (stdout, stderr, status, object) ->
  ret = if object? then object else {}

  ret.status ?= status
  ret.stderr ?= stderr
  ret.stdout ?= stdout

  ret
