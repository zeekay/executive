import Stream from 'stream'

class BufferStream extends Stream
  constructor: ->
    super()
    @buffer = ''
    @writable = true

  write: (data) ->
    @buffer += data

  end: (data) ->
    @write data if arguments.length
    @writable = false

  destroy: ->
    @writable = false

  toString: ->
    @buffer

export default BufferStream
