use 'sake-bundle'
use 'sake-outdated'
use 'sake-publish'
use 'sake-version'
use 'sake-test'

task 'build', 'build project', ->
  bundle.write
    entry: './src/index.coffee'
    compilers:
      coffee: version: 1

task 'watch', 'watch for changes and rebuild project', ->
  exec 'node_modules/.bin/coffee -bcmw -o lib/ src/'

task 'watch:test', 'watch for changes and rebuild, rerun tests', (options) ->
  invoke 'watch'

  require('vigil').watch __dirname, (filename) ->
    return if running 'test'

    if /^src/.test filename
      invoke 'test'

    if /^test/.test filename
      invoke 'test', test: filename
