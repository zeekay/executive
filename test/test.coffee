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

  it 'should spawn shell if glob or pipe detected', ->
    (yield exec 'echo foo | cat').stdout.should.eq 'foo\n'

  it 'should spawn shell if shell builtins detected', ->
    process.env.FOO = 1
    (yield exec 'echo $FOO').stdout.should.eq '1\n'

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

  it 'should collect results when commands are an object', ->
    {a, b, stderr} = yield exec.serial a: 'printf a', b: 'printf b'
    a.stdout.should.eq 'a'
    b.stdout.should.eq 'b'
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
      {stdout, stderr} = yield exec ['bash -c "exit 1"', "printf worked"]
      console.log stdout, stderr
      stdout.should.eq 'worked'
      stderr.should.eq ''

    it 'should continue processing, when strict mode is explicitly disabled, after a non-zero exit code', ->
      {stdout, stderr} = yield exec ['bash -c "exit 1"', "printf worked"], strict: false
      stdout.should.eq 'worked'
      stderr.should.eq ''

    it 'should not continue processing when strict mode is enabled after a non-zero exit code', ->
      p = exec ['bash -c "exit 1"', "printf worked"], strict: true
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

    it 'should collect results when commands are an object', ->
      {a, b, stderr} = yield exec.sync a: 'printf a', b: 'printf b'
      a.stdout.should.eq 'a'
      b.stdout.should.eq 'b'
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

    it 'should collect results when commands are an object', ->
      {a, b, stderr} = yield exec.parallel a: 'printf a', b: 'printf b'
      a.stdout.should.eq 'a'
      b.stdout.should.eq 'b'
      stderr.should.eq ''
