exec = require('../');

describe('executive', function() {
  describe('bufferedExec', function() {
    it('should buffer all stdout', function(done) {
      exec.bufferedExec('bash', ['-c', 'echo 1'], {}, function(err, stdout, stderr) {
        stdout.should.eq('1\n');
        done();
      });
    });

    it('should buffer all stderr', function(done) {
      exec.bufferedExec('bash', ['-c', 'doesnotexist'], {}, function(err, stdout, stderr) {
        stderr.should.contain('command not found');
        done();
      });
    });
  });

  describe('quietExec', function() {
    it('should buffer all stdout', function(done) {
      exec.quietExec('bash', ['-c', 'echo 1'], {}, function(err, stdout, stderr) {
        stdout.should.eq('1\n');
        done();
      });
    });

    it('should buffer all stderr', function(done) {
      exec.quietExec('bash', ['-c', 'doesnotexist'], {}, function(err, stdout, stderr) {
        stderr.should.contain('command not found');
        done();
      });
    });
  });

  describe('interactiveExec', function() {
    it('should not buffer stdout', function(done) {
      exec.interactiveExec('bash', ['-c', 'echo 1'], {}, function(err, stdout, stderr) {
        (stdout === null).should.equal(true);
        done();
      });
    });

    it('should not buffer stderr', function(done) {
      exec.interactiveExec('bash', ['-c', 'doesnotexist'], {}, function(err, stdout, stderr) {
        (stderr === null).should.equal(true);
        done();
      });
    });
  });
});
