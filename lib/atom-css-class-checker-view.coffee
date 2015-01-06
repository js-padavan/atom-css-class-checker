path = require 'path'
SimpleSelectListView = require './SimpleListView'
{CompositeDisposable} = require 'event-kit'

module.exports =
class entryView extends SimpleSelectListView
  visible: false

  initialize:  (@editor)->
    console.log 'initialize called'
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



  viewForItem: (item)->
    console.log 'child view for item', item
    "<li>
      <div class='sel'>#{item.sel}</div>
      <div class='linepos'>#{path.basename(item.file)}:#{item.pos.start.line}</div>
    </li>"

  confirmed: (item)->
    console.log "#{item} was selected"
    console.log(@onConfirm)
    @onConfirm?(item)

  selectNextItemView: ->
    console.log 'selecting next item'
    super
    false

  selectPreviousItemView: ->
    console.log 'selecting prev item'
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
    console.log @editor
    cursorMarker = @editor.getLastCursor().getMarker()
    @overlayDecoration = @editor.decorateMarker(cursorMarker, type: 'overlay', position: 'tail', item: this)
    console.log @overlayDecoration
    @visible = true

  # Toggle the visibility of this view
  toggle: ->
    if @visible
      @cancel()
    else
      @attach()

    console.log 'AtomPackageView was toggled!'

  cancel: =>
    return unless @active
    @visible = false;
    @overlayDecoration?.destroy()
    @overlayDecoration = undefined
    @compositeDisposable.dispose()
    super
    unless @editorView.hasFocus()
      @editorView.focus()
    # if @element.parentElement?
    #   @element.remove()
    # else
    #   atom.workspaceView.append(@element)
