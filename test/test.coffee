chai = require 'chai'
chai.should()
chai.use require 'chai-as-promised'

exec = require '../'

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

  it 'should split commands on multiple lines with spaces', ->
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

  it 'should shell out if necessary', ->
    {stdout} = yield exec 'echo foo | cat'
    stdout.should.eq 'foo\n'

  it 'should execute functions and promises as commands', ->
    val = null
    {stdout, stderr} = yield exec.serial [
      -> val = 1
      -> "bash -c 'sleep 1 && echo #{val}'"
      -> exec 'bash -c "echo 2"'
      'bash -c "echo 3"'
      -> {stdout: 4}
    ]
    stdout.should.eq '1\n2\n3\n4'
    stderr.should.eq ''

  describe 'promises', ->
    it 'should not reject non-zero status', ->
      {stdout, stderr, status} = yield exec.quiet 'bash -c doesnotexist'
      stdout.should.eq ''
      stderr.should.contain 'command not found'
      status.should.eq 127

    it 'should reject non-zero status with strict enabled', ->
      p = exec.quiet 'bash -c doesnotexist', strict: true
      yield p.should.be.rejectedWith Error

    it 'should continue processing, when strict mode is implicitly disabled, after a non-zero exit code', ->
      {stdout, stderr} = yield exec ['bash -c "exit 1"', "echo -n 'It worked'"]
      stdout.should.eq 'It worked'
      stderr.should.eq ''

    it 'should continue processing, when strict mode is explicitly disabled, after a non-zero exit code', ->
      {stdout, stderr} = yield exec ['bash -c "exit 1"', "echo -n 'It worked'"], { strict:false }
      stdout.should.eq 'It worked'
      stderr.should.eq ''

    it 'should not continue processing when strict mode is enabled after a non-zero exit code', ->
      p = exec ['bash -c "exit 1"', "echo -n 'It worked'"], { strict:true }
      yield p.should.be.rejectedWith Error

  describe 'interactive', ->
    it 'should not buffer output', ->
      {stdout, stderr} = yield exec.interactive 'bash -c "echo 1"'
      stdout.should.eq ''
      stderr.should.eq ''

      {stdout, stderr} = yield exec.interactive 'bash -c doesnotexist'
      stdout.should.eq ''
      stderr.should.eq ''

  describe 'sync', ->
    it 'should execute command synchronously', ->
      {stdout, stderr} = exec.sync 'bash -c "echo 1"'
      stdout.should.eq '1\n'
      stderr.should.eq ''

  describe 'parallel', ->
    it 'should execute commands in parallel', ->
      {stdout, stderr} = yield exec.parallel '''
      bash -c "sleep 1 && echo 1"
      bash -c "echo 2"
      bash -c "echo 3"
      '''
      stdout.should.eq '2\n3\n1\n'
      stderr.should.eq ''

    it 'should execute commands in parallel, including functions and promises', ->
      {stdout, stderr} = yield exec.parallel [
        -> "bash -c 'sleep 1 && echo 1'"
        -> exec 'bash -c "echo 2"'
        'bash -c "echo 3"'
        -> console.log 'ignored'
      ]
      lines = (x.trim() for x in stdout.trim().split '\n')
      lines.sort()
      lines.should.eql ['1', '2', '3']
      stderr.should.eq ''
