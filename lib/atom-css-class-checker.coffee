AtomPackageView = require './atom-css-class-checker'
fs = require 'fs'
walk = require 'walk'
path = require 'path'
_ = require 'lodash'

Manager = require './atom-css-class-checker-manager'



module.exports =
  # atomPackageView: null

  activate: (state) ->
    manager = new Manager()
    manager.init()
  
    # atom.commands.add 'atom-workspace', 'atom-package:toggle': => @atomPackageView.toggle()
    console.log 'atom-package loading';



  deactivate: ->
    @atomPackageView.destroy()

  serialize: ->
    atomPackageViewState: @atomPackageView.serialize()
