exec = require './'

task 'test', 'Run tests', ->
  exec "NODE_ENV=test
    ./node_modules/.bin/mocha
    --compilers coffee:coffee-script
    --reporter spec
    --colors
    --timeout 60000
    test"

task 'publish', 'Push current version to github and publish on npm', ->
  exec [
    'git push'
    'npm publish'
  ]
