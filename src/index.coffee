import {isFunction} from 'es-is'

import exec from './executive'

# Set defaults for various helpers
partial = (defaults) ->
  (cmds, opts, cb) ->
    [cb, opts] = [opts, {}] if isFunction opts
    exec cmds, (Object.assign {}, defaults, opts), cb

# Defaults
exec.interactive = partial interactive: true
exec.parallel    = partial parallel:    true
exec.quiet       = partial quiet:       true
exec.serial      = partial parallel:    false
exec.strict      = partial strict:      true
exec.sync        = partial sync:        true

export default exec
