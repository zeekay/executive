exec = require './'

task 'test', 'Run tests', ->
  exec "NODE_ENV=test
    ./node_modules/.bin/mocha
    --reporter spec
    --colors
    --timeout 60000
    test"

task 'publish', 'Push current version to github and publish on npm', ->
  exec [
    'git push'
    'git push --tags'
    'npm publish'
  ]
