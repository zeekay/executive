exec = require('../');

describe('executive', function() {
  describe('bufferedExec', function() {
    it('should buffer all stdout', function(done) {
      exec.bufferedExec('zsh', ['-c', 'echo 1'], {}, function(err, out, code) {
        out.should.eq('1\n')
        done()
      })
    })

    it('should buffer all stderr', function(done) {
      exec.bufferedExec('zsh', ['-c', 'doesnotexist'], {}, function(err, out, code) {
        err.should.contain('command not found')
        done()
      })
    })
  })

  describe('quietExec', function() {
    it('should buffer all stdout', function(done) {
      exec.quietExec('zsh', ['-c', 'echo 1'], {}, function(err, out, code) {
        out.should.eq('1\n')
        done()
      })
    })

    it('should buffer all stderr', function(done) {
      exec.quietExec('zsh', ['-c', 'doesnotexist'], {}, function(err, out, code) {
        err.should.contain('command not found')
        done()
      })
    })
  })

  describe('interactiveExec', function() {
    it('should not buffer stdout', function(done) {
      exec.interactiveExec('zsh', ['-c', 'echo 1'], {}, function(err, out, code) {
        (out == null).should.be.true
        done()
      })
    })

    it('should not buffer stderr', function(done) {
      exec.interactiveExec('zsh', ['-c', 'doesnotexist'], {}, function(err, out, code) {
        (err == null).should.be.true
        done()
      })
    })
  })
})
