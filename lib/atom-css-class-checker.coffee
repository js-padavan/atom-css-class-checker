AtomPackageView = require './atom-css-class-checker'
fs = require 'fs'
walk = require 'walk'
path = require 'path'

SSParser = require './stylesParser'



module.exports =
  # atomPackageView: null

  activate: (state) ->
    atom.workspace.onDidOpen (event)->
      console.log event
    atom.workspace.observeTextEditors (editor)->
      console.log 'new editor', editor
      r = /class="([\w|\s|-]*)"/gmi
      editor.scan r, (it)->
        it.range.start.column += it.matchText.indexOf('"');
        editor.scanInBufferRange /([\w|-]+)/ig, it.range, (it)->
          console.log it
          marker = editor.markBufferRange(it.range, invalidate: 'never')
          editor.decorateMarker(marker, type: 'highlight', class: 'myclass')
    # editor = atom.workspace.getActiveTextEditor()
    # console.log editor
    # @atomPackageView = new AtomPackageView(editor)
    # atom.commands.add 'atom-workspace', 'atom-package:toggle': => @atomPackageView.toggle()
    console.log 'atom-package loading';
    # parser = new SSParser();

    # prjDir = atom.project.getPaths()
    # prjFiles = getSSFiles(prjDir)
    # atom.workspace.onDidChangeActivePaneItem (event)->
    #   console.log('pane changed', event);
    #   TE = atom.workspace.getActiveTextEditor();
    #   console.log TE
    #   TE.onDidStopChanging ()->
    #     row = TE.getCursorBufferPosition().row;
    #     console.log row
    #     curLine = TE.lineTextForBufferRow(row);
    #     parseHtmlInput curLine;
  deactivate: ->
    @atomPackageView.destroy()

  serialize: ->
    atomPackageViewState: @atomPackageView.serialize()
