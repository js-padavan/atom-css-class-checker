SSParser = require './stylesParser'
_ = require 'lodash'
{CompositeDisposable, Disposable} = require 'event-kit'
path = require 'path'



class Manager

  constructor: ->
    @parser = null
    @prevEditor = {}
    @disposables = []
    @htmlContFiles = ['.html', '.php']
    @cssFiles = ['.css', '.less']
    @running = false

  init: ->
    @parser = new SSParser()
    @parser.loaded.then =>
      # subscribing only on files which may contain HTML
      compositeDisposable = new CompositeDisposable()
      @disposables['global'] = compositeDisposable
      compositeDisposable.add  atom.workspace.observeTextEditors (editor)=>
        title = editor.getTitle()
        if @containsHtml(title)
          @subscribeOnHtmlEditorEvents(editor)
          @parseEditor(editor)
          # subscribing on parser updates
          @parser.onDidUpdate =>
            console.log 'reparsing editor ', editor.getTitle()
            @parseEditor(editor)

      #  susbscribing on css changes
      @watchCssChangings()
    @running = true


  containsHtml: (filename)->
    return (_.indexOf(@htmlContFiles, path.extname(filename)) != -1)

  containsCss: (filename)->
    return (_.indexOf(@cssFiles, path.extname(filename)) != -1)

  watchCssChangings: ->
    disposable = null
    getPrevEditor = (editor)=>
      @prevEditor.editor = editor || atom.workspace.getActivePaneItem()
      if (@prevEditor.editor == undefined)
        disposable?.dispose()
        dispose = null
        return
      @prevEditor.isCss = @containsCss(@prevEditor.editor.getTitle())
      @prevEditor.modified = false
      disposable?.dispose()
      if @prevEditor.isCss
        disposable = editor.onDidStopChanging =>
          @prevEditor.modified = true
          disposable.dispose()
          disposable = null
      else
        disposable = null
      console.log @prevEditor

    getPrevEditor()

    @disposables['global'].add atom.workspace.onDidChangeActivePaneItem (item)=>
      # parsing css file if it is required
      if (@prevEditor.isCss && @prevEditor.modified)
        console.log 'parsing required'
        @parser.updateWithSSFile(@prevEditor.editor.getUri(), @prevEditor.editor.getText())
      getPrevEditor(item)


  subscribeOnHtmlEditorEvents: (editor)->
    editorUri = editor.getUri()
    compositeDisposable = new CompositeDisposable()

      # reparsing file on changings
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
    r = /class="([\w|\s|\-|_]*)"/gmi
    i = /id\s*=\s*["|']\s*([\w|\-|_]*)\s*["|']/gmi
    #  scanning for clasees
    editor.scanInBufferRange r, range, (it)=>
      it.range.start.column += it.matchText.indexOf('"')
      @scanInRange(it.range, editor)
    # scanning for ids
    editor.scan i, (it)=>
      it.range.start.column += it.matchText.indexOf('"')
      @highlightIdRange(it.range, it.match[1], editor)

  parseEditor: (editor)->
    c = /class=["|']([\w|\s|\-|_]*)["|']/gmi
    i = /id\s*=\s*["|']\s*([\w|\-|_]*)\s*["|']/gmi
    # scanning for classes
    editor.scan c, (it)=>
      it.range.start.column += it.matchText.indexOf('"')
      @scanInRange(it.range, editor)
    # scanning for ids
    editor.scan i, (it)=>
      it.range.start.column += it.matchText.indexOf('"')
      @highlightIdRange(it.range, it.match[1], editor)

  highlightClassRange: (range, text, editor)->
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

  highlightIdRange: (range, text, editor)->
    return unless range isnt undefined and text isnt undefined and editor isnt undefined
    #  removing old markers in the range
    oldMarkers = editor.findMarkers(containsBufferRange: range)
    for i in [0...oldMarkers.length]
      oldMarkers[i].destroy()

    marker = editor.markBufferRange(range, invalidate: 'overlap')
    if (_.findIndex(@parser.ids, name: text) != -1)
      editor.decorateMarker(marker, type: 'highlight', class: 'existed-class')
    else
      editor.decorateMarker(marker, type: 'highlight', class: 'non-existed-class')

  scanInRange: (range, editor)->
    r = /([\w|\-|_]+)/ig
    editor.scanInBufferRange r, range, (it)=>
      @highlightClassRange(it.range, it.matchText, editor)

  cancel: ->
    for k,v of @disposables
      v.dispose()
    @running = false

  toggle: ->
    if @running
      console.log 'pausing'
      @cancel()
    else
      console.log 'starting'
      @init()

module.exports = Manager
