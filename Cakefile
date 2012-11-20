exec = require './'

task 'test', 'run tests', ->
  exec "NODE_ENV=test
    ./node_modules/.bin/mocha
    --compilers coffee:coffee-script
    --reporter spec
    --colors
    --timeout 60000
    test"

task 'publish', 'Publish current version to NPM', ->
  exec [
    'git push'
    'npm publish'
  ]
