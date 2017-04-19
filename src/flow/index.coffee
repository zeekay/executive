import {isArray, isObject, isString} from 'es-is'

import exec     from '../exec'
import execSync from '../execSync'
import parallel from './parallel'
import serial   from './serial'


# Execute array of commands, with serial exution by default
array = (ex, arr, opts, cb) ->
  if opts.parallel
    parallel ex, arr, opts, cb
  else
    serial ex, arr, opts, cb


# Execute string representing commands
string = (ex, str, opts, cb) ->
  arr = (str.split '\n').filter (c) -> c != ''
  array ex, arr, opts, cb


# Execute object of commands
object = (ex, obj, opts, cb) ->
  ret  = Object.assign {}, obj
  cmds = ([k,v] for k,v of obj)

  # Synchronous command exution, neither parallel nor serial matter
  if opts.sync
    for [k, cmd] in cmds
      serial ex, cmds, opts, (err, stdout, stderr, status) ->


# Execute commands using either serial or parallel control flow and return
# result to cb
export default (cmds, opts, cb) ->
  # Use sync exec if necessary
  ex = if opts.sync then execSync else exec

  if isString cmds
    return string ex, cmds, opts, cb
  if isObject cmds
    return object ex, cmds, opts, cb
  if isArray cmds
    return array ex, cmds, opts, cb

  throw new Error "Unable to return results for cmds = #{JSON.stringify cmds}"
