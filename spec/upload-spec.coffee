Existdb = require '../lib/existdb'
_path = require 'path'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block. To mark either as pending
# add an `x` (e.g. `xit`).

# This is an integration test and requires a running eXist-db instance.

xdescribe "when user uploads files", ->
  # see #5
  it 'succeeds with xml', ->
    expect().toExist()
  it 'succeeds with xquery', ->
    expect().toExist()
  it 'succeeds with binary', ->
    expect().toExist()
