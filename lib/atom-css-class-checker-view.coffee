SimpleSelectListView = require './SimpleListView'
{CompositeDisposable} = require 'event-kit'

module.exports =
class entryView extends SimpleSelectListView
  visible: false

  initialize:  (@editor)->
    console.log 'initialize called'
    super
    @editorView = atom.views.getView(@editor)
    @addClass('popover-list atom-package')

    @compositeDisposable = new CompositeDisposable
    @compositeDisposable.add atom.commands.add '.atom-package',
      "atom-package:confirm": @confirmSelection,
      "atom-package:select-next": @selectNextItemView,
      "atom-package:select-previous": @selectPreviousItemView,
      "atom-package:cancel": @cancel



  viewForItem: (item)->
    "<li>#{item}</li>"

  confirmed: (item)->
    console.log "#{item} was selected"

  # selectNextItemView: ->
  #   super
  #   false
  #
  # selectPreviousItemView: ->
  #   super
  #   false

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
    @setItems(['test1', 'test2'])
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
    super
    unless @editorView.hasFocus()
      @editorView.focus()
    # if @element.parentElement?
    #   @element.remove()
    # else
    #   atom.workspaceView.append(@element)
