import {isArray, isObject, isString} from 'es-is'

import async    from '../spawn/async'
import sync     from '../spawn/sync'
import parallel from './parallel'
import serial   from './serial'


# Execute array of commands, with serial exution by default
array = (exec, cmds, opts, cb) ->
  if opts.parallel
    parallel exec, cmds, opts, cb
  else
    serial exec, cmds, opts, cb


# Execute string representing commands
string = (exec, str, opts, cb) ->
  cmds = (s for s in str.split '\n' when s.trim() != '')
  array exec, cmds, opts, cb


# Execute object of commands
object = (exec, obj, opts, cb) ->
  cmds = ([k, cmd] for k, cmd of obj)
  array exec, cmds, opts, cb


# Execute commands using either serial or parallel control flow and return
# result to cb
export default (cmds, opts, cb) ->
  # Use sync exec if necessary
  exec = if opts.sync then sync else async

  if isString cmds
    return string exec, cmds, opts, cb
  if isObject cmds
    return object exec, cmds, opts, cb
  if isArray cmds
    return array exec, cmds, opts, cb

  throw new Error "Unable to return results for cmds = #{JSON.stringify cmds}"
