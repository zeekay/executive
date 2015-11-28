chai = require 'chai'
chai.should()
chai.use require 'chai-as-promised'

exec = require '../lib'

describe 'exec', ->
  it 'should accept Node.js style callbacks', (done) ->
    exec.quiet 'bash -c "echo 1"', (err, stdout, stderr) ->
      stdout.should.eq '1\n'
      done()

  it 'should expose Promise API', ->
    {stdout} = yield exec.quiet 'bash -c "echo 1"'
    stdout.should.eq '1\n'

  it 'should split commands on multiple lines', ->
    {stdout} = yield exec.quiet '''
    bash -c "echo 1"
    bash -c "echo 2"
    bash -c "echo 3"
    '''
    stdout.should.eq '1\n2\n3\n'

  it 'should buffer all stdout', (done) ->
    exec.quiet 'bash -c "echo 1"', (err, stdout, stderr) ->
      stdout.should.eq '1\n'
      done()

  it 'should buffer all stderr', (done) ->
    exec.quiet 'bash -c doesnotexist', (err, stdout, stderr) ->
      stderr.should.contain 'command not found'
      done()

  describe 'interactive', ->
    it 'should not buffer stdout', ->
      {stdout} = yield exec.interactive 'bash -c "echo 1"'

    it 'should not buffer stderr', ->
      try
        yield exec.interactive 'bash -c doesnotexist'
      catch err
      err.stderr.should.equal ''
