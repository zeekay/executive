exec = require('../');

describe('executive', function() {
  describe('bufferedExec', function() {
    it('should buffer all stdout', function(done) {
      exec.bufferedExec('ls', [], {}, function(err, out, code) {
        out.should.not.eq('')
        done()
      })
    })

    it('should buffer all stderr', function(done) {
      done()
    })
  })
})
