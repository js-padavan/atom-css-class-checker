path = require 'path'
SimpleSelectListView = require './SimpleListView'
{CompositeDisposable} = require 'event-kit'

class PopupList extends SimpleSelectListView
  visible: false

  initialize:  (@editor)->
    console.log 'popupinit with', @editor, arguments
    super
    @editorView = atom.views.getView(@editor)
    @addClass('popover-list atom-css-class-checker-popup')
    @onConfirm = undefined;

    @compositeDisposable = new CompositeDisposable
    @compositeDisposable.add atom.commands.add '.atom-css-class-checker-popup',
      "atom-css-class-checker:confirm": @confirmSelection,
      "atom-css-class-checker:select-next": @selectNextItemView,
      "atom-css-class-checker:select-previous": @selectPreviousItemView,
      "atom-css-class-checker:cancel": @cancel


  confirmed: (item)->
    @onConfirm?(item)

  selectNextItemView: ->
    super
    false

  selectPreviousItemView: ->
    super
    false

  # constructor: (serializeState) ->
  #
  #   # test = @div class: 'panel, bordered'
  #   console.log 'test'
  #   console.log atom.workspaceView
  #
  #   # Register command that toggles this view
  #   atom.commands.add 'atom-workspace', 'atom-package:toggle': => @toggle()

  # # Returns an object that can be retrieved when package is activated
  # serialize: ->
  #
  # # Tear down any state and detach
  # destroy: ->


  attach: ->
    cursorMarker = @editor.getLastCursor().getMarker()
    @overlayDecoration = @editor.decorateMarker(cursorMarker, type: 'overlay', position: 'tail', item: this)
    @visible = true

  # Toggle the visibility of this view
  toggle: ->
    if @visible
      @cancel()
    else
      @attach()


  cancel: =>
    return unless @active
    @visible = false;
    @overlayDecoration?.destroy()
    @overlayDecoration = undefined
    @compositeDisposable.dispose()
    super
    unless @editorView.hasFocus()
      @editorView.focus()


class ReferencesList extends PopupList
  initialize: (editor)->
    super

  viewForItem: (item)->
    "<li>
      <div class='sel'>#{item.sel}</div>
      <div class='linepos'>#{path.basename(item.file)}:#{item.pos.start.line}</div>
    </li>"

class FilesList extends PopupList
  initialize: (editor)->
    super
    @title.text "define in:"

  viewForItem: (item)->
    prjPath = atom.project.getPath();
    "<li>
      <div class='sel'>#{item.filename}</div>
      <div class='linepos'>#{item.path.replace(prjPath, '.')}</div>
    </li>"

module.exports.PopupList = PopupList
module.exports.ReferencesList = ReferencesList
module.exports.FilesList = FilesList
