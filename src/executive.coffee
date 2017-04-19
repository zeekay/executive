import {isFunction} from 'es-is'

import flow from './flow'
import {mergeResult} from './utils'


# Return executive results asynchronously
async = (cmds, opts, cb) ->
  flow cmds, opts, (err, stdout, stderr, status, object) ->
    if object?
      obj = mergeResult stdout, stderr, status, object
      cb err, obj, stdout, stderr, status
    else
      cb err, stdout, stderr, status


# Return executive results synchronously
sync = (cmds, opts) ->
  ret = null

  # This happens synchronously
  flow cmds, opts, (err, stdout, stderr, status, object) ->
    if opts.syncThrows
      if opts.strict and status != 0
        throw err
      else if err? and not status?
        throw err

    ret = mergeResult stdout, stderr, status, object

  ret


# Return executive results as promise
promise = (cmds, opts) ->
  new Promise (resolve, reject) ->
    flow cmds, opts, (err, stdout, stderr, status, object) ->
      if opts.strict and status != 0
        return reject err
      else if err? and not status?
        return reject err

      resolve mergeResult stdout, stderr, status, object


# Run string, array or object commands and return results
export default (cmds, opts, cb) ->
  # Passed only callback
  if isFunction opts
    [cb, opts] = [opts, {}]

  # Ensure opts exists
  opts ?= {}

  # Async exec with errback-style callback
  return async cmds, opts, cb if isFunction cb

  # Blocking exec
  return sync cmds, opts if opts.sync

  # Async exec with Promise API expected
  return promise cmds, opts
