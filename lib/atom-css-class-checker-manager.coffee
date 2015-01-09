SSParser = require './stylesParser'
_ = require 'lodash'
{CompositeDisposable, Disposable} = require 'event-kit'
path = require 'path'
{PopupList, ReferencesList, FilesList} = require './atom-css-class-checker-view'



class Manager

  constructor: ->
    @parser = null
    @prevEditor = {}
    @disposables = []
    @htmlContFiles = ['.html', '.php']
    @cssFiles = ['.css']
    @running = false
    @editorsMarkers = []

    atom.commands.add 'atom-workspace', 'atom-css-class-checker:toggle': =>
      @toggle()

    atom.commands.add 'atom-workspace', 'atom-css-class-checker:open-source': =>
      console.log 'opening source'
      @openSource()


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
      @subscribeOnSettingsChanges()
    @running = true

  containsHtml: (filename)->
    return (_.indexOf(@htmlContFiles, path.extname(filename)) != -1)

  containsCss: (filename)->
    return (_.indexOf(@cssFiles, path.extname(filename)) != -1)

  watchCssChangings: ->
    console.log 'watching CSSSSSS chanfes';
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
          console.log 'modified';
          @prevEditor.modified = true
          disposable.dispose()
          disposable = null
      else
        disposable = null

    getPrevEditor()
    @disposables['global'].add atom.workspace.onDidChangeActivePaneItem (item)=>
      console.log 'on did change';
      # parsing css file if it is required
      if (@prevEditor.isCss && @prevEditor.modified)
        console.log 'did parsing required'
        @parser.updateWithSSFile(@prevEditor.editor.getUri(), @prevEditor.editor.getText())
        @prevEditor.modified = false;
      getPrevEditor(item)


  subscribeOnHtmlEditorEvents: (editor)->
    editorUri = editor.getUri()
    compositeDisposable = new CompositeDisposable()

      # reparsing file on changings
    compositeDisposable.add editor.onDidStopChanging =>
       range = editor.getCurrentParagraphBufferRange()
       @parseTextRage(range, editor) unless range == undefined

    compositeDisposable.add editor.onDidDestroy =>
      console.log 'on did close'
      @disposables[editorUri]?.dispose()
      @disposables[editorUri] = null


    @disposables[editorUri] = compositeDisposable

  subscribeOnSettingsChanges: ()->
    @disposables['global'].add atom.config.onDidChange 'atom-css-class-checker.checkIds', =>
      @cancel()
      @init()

  parseTextRage: (range, editor)->
    checkIds = atom.config.get('atom-css-class-checker.checkIds')
    @removeEditorMarkersInRange(range, editor)
    r = /class="([\w|\s|\-|_]*)"/gmi
    i = /id\s*=\s*["|']\s*([\w|\-|_]*)\s*["|']/gmi
    #  scanning for clasees
    editor.scanInBufferRange r, range, (it)=>
      it.range.start.column += it.matchText.indexOf('"')
      @scanInRange(it.range, editor)
    # scanning for ids
    if checkIds
      editor.scan i, (it)=>
        it.range.start.column += it.matchText.indexOf('"')
        @highlightIdRange(it.range, it.match[1], editor)

  parseEditor: (editor)->
    checkIds = atom.config.get('atom-css-class-checker.checkIds')
    @removeAllEditorMarkers(editor)
    c = /class=["|']([\w|\s|\-|_]*)["|']/gmi
    i = /id\s*=\s*["|']\s*([\w|\-|_]*)\s*["|']/gmi
    # scanning for classes
    editor.scan c, (it)=>
      it.range.start.column += it.matchText.indexOf('"')
      @scanInRange(it.range, editor)
    # scanning for ids
    if checkIds
      editor.scan i, (it)=>
        it.range.start.column += it.matchText.indexOf('"')
        @highlightIdRange(it.range, it.match[1], editor)

  removeEditorMarkersInRange: (range, editor)->
    markers = @editorsMarkers[editor.getUri()]
    return unless markers
    for i in [0...markers.length]
      if range.containsRange(markers[i].bufferMarker.range)
        markers[i].destroy()
        markers[i] = null
    @editorsMarkers[editor.getUri()] = _.compact(markers)

  removeAllEditorMarkers: (editor)->
    uri = editor.getUri()
    markers =  @editorsMarkers[uri]
    return unless markers
    for i in [0...markers.length]
      markers[i].destroy()
    @editorsMarkers[uri].length = 0


  removeAllMarkers: ->
    for k,v of @editorsMarkers
      for i in [0...@editorsMarkers[k].length]
        @editorsMarkers[k][i].destroy()
      delete @editorsMarkers[k]

  createEditorMarker: (editor, range, type)->
    marker = editor.markBufferRange(range, invalidate: 'overlap')
    marker.type = type;
    uri = editor.getUri()
    if @editorsMarkers[uri] != undefined
      @editorsMarkers[uri].push(marker)
    else
      @editorsMarkers[uri] = [marker]
    return marker

  highlightClassRange: (range, text, editor)->
    return unless range isnt undefined and text isnt undefined and editor isnt undefined
    marker = @createEditorMarker(editor, range, 'class')
    if (_.findIndex(@parser.classes, name: text) != -1)
      editor.decorateMarker(marker, type: 'highlight', class: 'existed-class')
    else
      editor.decorateMarker(marker, type: 'highlight', class: 'non-existed-class')


  highlightIdRange: (range, text, editor)->
    return unless range isnt undefined and text isnt undefined and editor isnt undefined
    marker = @createEditorMarker(editor, range, 'id')
    if (_.findIndex(@parser.ids, name: text) != -1)
      editor.decorateMarker(marker, type: 'highlight', class: 'existed-class')
    else
      editor.decorateMarker(marker, type: 'highlight', class: 'non-existed-class')

  scanInRange: (range, editor)->
    r = /([\w|\-|_]+)/ig
    editor.scanInBufferRange r, range, (it)=>
      @highlightClassRange(it.range, it.matchText, editor)

  cancel: ->
    @removeAllMarkers()
    delete @parser
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

  openSource: ->
    # opens editor with specified filename
    # if line param not specified when the editor will be opened on the last line
    openEditor = (filename, line=0)->
      openInSplit = atom.config.get('atom-css-class-checker.openSourceInSplitWindow');
      options =
        split: if openInSplit then 'right' else undefined
      atom.workspace.open(filename, options)
      .then (editor)->
        editor.setCursorBufferPosition([line, 0])
        editor.scrollToCursorPosition()
        return editor

    onConfirmReference = (item) ->
      openEditor(item.file, item.pos.start.line)

    onConfirmFile = (item) ->
      console.log 'onConfirmFileCalled'
      openEditor(item.path, 0).then (editor)->
        editor.setCursorScreenPosition [editor.getScreenLineCount(), 0]

    toggleReferencesList = (items, editor) ->
      popup = new ReferencesList(editor)
      popup.setItems(items)
      popup.onConfirm = onConfirmReference
      popup.toggle()

    toggleFilesList = (items, editor)->
      popup = new FilesList(editor)
      popup.setItems(items)
      popup.onConfirm = onConfirmFile
      popup.toggle()

    getMarkerInfo = (editor) =>
      markers = @editorsMarkers[editor.getUri()]
      cursorPoint = editor.getCursorBufferPosition()
      for i in [0...markers.length]
        range = markers[i].getBufferRange();
        if range.containsPoint(cursorPoint)
          console.log 'contains', markers[i];
          text = editor.getTextInBufferRange(range);
          type = markers[i].type;
          break
      return text: text, type: type

    findSelectors = (type, selName) =>
      findReferences = (selectors, selName) =>
        subsels = _.filter(selectors, name: selName)
        res = []
        for i in [0...subsels.length]
          res = res.concat(subsels[i].references)
        return res

      switch type
        when 'class'
          return findReferences(@parser.classes, selName);
        when 'id'
          return findReferences(@parser.ids, selName)



    editor = atom.workspace.getActiveTextEditor()
    markerInfo = getMarkerInfo(editor)
    return unless markerInfo.text != undefined
    references = findSelectors(markerInfo.type, markerInfo.text)
    switch references.length
      when 0
        items = _.map @parser.ssFiles, (file)->
          return {
            filename: path.basename(file),
            path: file
          }
        toggleFilesList items, editor
        break;
      when 1
        openEditor references[0].file, references[0].pos.start.line
        break;
      else
        console.log editor
        toggleReferencesList references, editor
        break;





module.exports = Manager
