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
    # parser = new SSParser();
    # console.log parser
    # editor = null
    #

    #
    #
    # parser.loaded.then ->
    #   console.log "parser loaded"
    #
    #
    #   atom.workspace.onDidOpen (event)->
    #     console.log event
    #
    #   atom.workspace.observeTextEditors (editor)->
    #     console.log 'new editor', editor
    #     editor.onDidStopChanging ->
    #       range = editor.getCurrentParagraphBufferRange()
    #       console.log range
    #       scanInRange(range, editor)
    #
    #
    #
    #     r = /class="([\w|\s|-]*)"/gmi
    #     editor.scan r, (it)->
    #       it.range.start.column += it.matchText.indexOf('"');
    #       editor.scanInBufferRange /([\w|-]+)/ig, it.range, (it)->
    #         console.log it
    #         marker = editor.markBufferRange(it.range, invalidate: 'never')
    #         if (_.findIndex(parser.classes, name: it.matchText) != -1)
    #           editor.decorateMarker(marker, type: 'highlight', class: 'existed-class')
    #         else
    #           editor.decorateMarker(marker, type: 'highlight', class: 'non-existed-class')
    #
    #


    # editor = atom.workspace.getActiveTextEditor()
    # console.log editor
    # @atomPackageView = new AtomPackageView(editor)
    # atom.commands.add 'atom-workspace', 'atom-package:toggle': => @atomPackageView.toggle()
    console.log 'atom-package loading';



  deactivate: ->
    @atomPackageView.destroy()

  serialize: ->
    atomPackageViewState: @atomPackageView.serialize()
