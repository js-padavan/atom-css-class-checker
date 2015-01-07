AtomPackageView = require './atom-css-class-checker'
fs = require 'fs'
walk = require 'walk'
path = require 'path'
_ = require 'lodash'

Manager = require './atom-css-class-checker-manager'



module.exports =
  config:
    ignoreDirectories:
      type: 'array',
      title: 'Ignore Directories',
      default: ['node_modules/', '.git/', './bower_components/']
      items:
        type: 'string'
    ignoreFiles:
      type: 'array'
      title: 'Ignore Files'
      default: []
      items:
        type: 'string'
    checkIds:
      type: 'boolean',
      default: true
    openSourceInSplitWindow:
      type: 'boolean',
      default: true

  activate: (state) ->
    @manager = new Manager()


  deactivate: ->
    console.log 'deactivating'
    @manager.cancel()

  serialize: ->
    # atomPackageViewState: @atomPackageView.serialize()
