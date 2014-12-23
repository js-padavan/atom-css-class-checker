AtomPackageView = require './atom-css-class-checker'
fs = require 'fs'
walk = require 'walk'
path = require 'path'
_ = require 'lodash'

Manager = require './atom-css-class-checker-manager'



module.exports =
  # atomPackageView: null

  activate: (state) ->
    @manager = new Manager()

    atom.commands.add 'atom-workspace', 'atom-css-class-checker:toggle': =>
      @manager.toggle()

    console.log 'atom-package loading';

  deactivate: ->
    # @atomPackageView.destroy()
    console.log 'deactivating'
    @manager.cancel()

  serialize: ->
    # atomPackageViewState: @atomPackageView.serialize()
