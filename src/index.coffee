import {isFunction} from 'es-is'

import executive    from './executive'

# Setup defaults for various shortcut helpers
partial = (defaults) ->
  (cmds, opts, cb) ->
    if isFunction opts
      [cb, opts] = [opts, {}]

    opts = Object.assign {}, defaults, opts ? {}

    executive cmds, opts, cb

# Defaults
wrapper = partial quiet: false, interactive: false, sync: false

wrapper.interactive = partial interactive: true
wrapper.parallel    = partial parallel:    true
wrapper.quiet       = partial quiet:       true
wrapper.sync        = partial sync:        true

export default wrapper
