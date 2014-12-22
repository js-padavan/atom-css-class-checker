SSParser = require './stylesParser'
_ = require 'lodash'
{CompositeDisposable} = require 'event-kit'
path = require 'path'



class Manager

  constructor: ->
    @parser = null
    @prevFile = undefined
    @disposables = []
    @filesToSubscribe = ['.html', '.php']
    @styleFiles = ['.css', '.less']

  init: ->
    @parser = new SSParser()
    @parser.loaded.then =>
      atom.workspace.observeTextEditors (editor)=>
        console.log "new editor!"
        # subscribin only on specific filetypes
        title = editor.getTitle()
        if _.indexOf(@filesToSubscribe, path.extname(title)) != -1
          @subscribeOnEditorEvents(editor)
          @parseEditor(editor)

      @prevFile = atom.workspace.getActivePaneItem().getUri()
      atom.workspace.onDidChangeActivePaneItem (item)=>
        console.log @prevFile, _.indexOf(@styleFiles, path.extname(@prevFile))
        # if it was stylesheet file, then it is required to update parser
        if _.indexOf(@styleFiles, path.extname(@prevFile)) != -1
          console.log 'updating parser'
          @parser.parseSSFile(@prevFile)
        @prevFile = item.getUri()



  subscribeOnEditorEvents: (editor)->
    console.log "subs on events"
    editorUri = editor.getUri()
    compositeDisposable = new CompositeDisposable()

    compositeDisposable.add editor.onDidStopChanging =>
       range = editor.getCurrentParagraphBufferRange()
       console.log editor, range
       @parseTextRage(range, editor) unless range == undefined

    compositeDisposable.add editor.onDidDestroy =>
      console.log 'on did close'
      @disposables[editorUri].dispose()
      @disposables[editorUri] = null


    @disposables[editorUri] = compositeDisposable

  parseTextRage: (range, editor)->
    r = /class="([\w|\s|-]*)"/gmi
    i = /id\s*=\s*"\s*([\w|-]*)\s*"/gmi
    #  scanning for clasees
    editor.scanInBufferRange r, range, (it)=>
      it.range.start.column += it.matchText.indexOf('"')
      @scanInRange(it.range, editor)
    # scanning for ids
    editor.scan i, (it)=>
      it.range.start.column += it.matchText.indexOf('"')
      @highlightRange(it.range, it.match[1], editor)

  parseEditor: (editor)->
    c = /class="([\w|\s|-]*)"/gmi
    i = /id\s*=\s*"\s*([\w|-]*)\s*"/gmi
    # scanning for classes
    editor.scan c, (it)=>
      it.range.start.column += it.matchText.indexOf('"')
      @scanInRange(it.range, editor)
    # scanning for ids
    editor.scan i, (it)=>
      it.range.start.column += it.matchText.indexOf('"')
      @highlightRange(it.range, it.match[1], editor)

  highlightRange: (range, text, editor)->
    return unless range isnt undefined and text isnt undefined and editor isnt undefined
    #  removing old markers in the range
    oldMarkers = editor.findMarkers(containsBufferRange: range)
    for i in [0...oldMarkers.length]
      oldMarkers[i].destroy()

    marker = editor.markBufferRange(range, invalidate: 'overlap')
    if (_.findIndex(@parser.classes, name: text) != -1)
      editor.decorateMarker(marker, type: 'highlight', class: 'existed-class')
    else
      editor.decorateMarker(marker, type: 'highlight', class: 'non-existed-class')

  scanInRange: (range, editor)->
    r = /([\w|-]+)/ig
    editor.scanInBufferRange r, range, (it)=>
      @highlightRange(it.range, it.matchText, editor)


module.exports = Manager
