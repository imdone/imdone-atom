{$, $$, $$$, View, TextEditorView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'

module.exports =
class ConfigView extends View

  @content: ->
    @div class:'imdone-config-container', =>
      @div outlet: 'resizer', class:'split-handle-y'
      @div outlet: 'closeButton', class:'close-button', =>
        @raw '&times;'
      @div outlet: 'error', class:'text-error'
      @div outlet: 'renameList', class:'rename-list config-panel', =>
        @h2 =>
          @span outlet:'renameListLabel'
        @div class: 'block', =>
          @div class: 'input-small', =>
            @subview 'renameListField', new TextEditorView(mini: true)
          @button click: 'cancelRename', class:'inline-block-tight btn', 'Forget it'
          @button click: 'doListRename', class:'inline-block-tight btn btn-primary', 'Looks good'
      @div outlet: 'newList', class:'new-list config-panel', =>
        @h2 'New List'
        @div class: 'block', =>
          @div class: 'input-small', =>
            @subview 'newListField', new TextEditorView(mini: true)
          @button click: 'cancelNewList', class:'inline-block-tight btn', 'Forget it'
          @button click: 'doNewList', class:'inline-block-tight btn btn-primary', 'Looks good'
      @div outlet: 'plugins', class:'imdone-plugins-container config-panel'
      # #BACKLOG:0 Add config view here

  initialize: ({@imdoneRepo, @path, @uri}) ->
    @emitter = new Emitter
    @handleEvents()

  handleEvents: ->
    # #DONE:0 Make resizable when open [Edit fiddle - JSFiddle](http://jsfiddle.net/3jMQD/614/)
    startY = startHeight = null
    container = this
    @resizer.on 'mousedown', (e) =>
      e.stopPropagation()
      e.preventDefault()
      container.emitter.emit 'resize.start'
      startY = e.clientY
      startHeight = container.height()
      $imdoneAtom = container.closest('.pane-item')
      doDrag = (e) =>
        e.preventDefault()
        e.stopPropagation()
        height = startHeight + startY - e.clientY
        container.height(height)
        container.emitter.emit 'resize.change', height

      stopDrag = (e) =>
        container.emitter.emit 'resize.stop'
        $imdoneAtom.off 'mousemove', doDrag
        $imdoneAtom.off 'mouseup', stopDrag

      $imdoneAtom.on 'mousemove', doDrag
      $imdoneAtom.on 'mouseup', stopDrag

    @newListField.on 'keyup', (e) =>
      code = e.keyCode || e.which
      if(code == 13)
        @doNewList()
      if(code ==27)
        @cancelNewList()

    @renameListField.on 'keyup', (e) =>
      code = e.keyCode || e.which
      if(code == 13)
        @doListRename()
      if(code ==27)
        @cancelRename()

    @imdoneRepo.on 'list.modified', (list) =>
      @hide()

    @closeButton.on 'click', =>
      @hide()

  isOpen: ->
    @hasClass 'open'

  show: ->
    unless @isOpen()
      @emitter.emit 'config.open'
      @addClass 'open'

  hide: ->
    @find('.config-panel').hide()
    if @isOpen()
      @error.empty()
      @removeClass 'open'
      @css 'height', ''
      @emitter.emit 'config.close'

  setHeight: (px) ->
    @height(px)
    @emitter.emit 'resize.change', px

  addPlugin: (plugin) ->
    pluginView = plugin.getView()
    pluginView.addClass "imdone-plugin #{plugin.constructor.pluginName}"
    pluginView.appendTo @plugins
    plugin.on 'view.show', => @showPlugin plugin

  showPlugin: (plugin) ->
    @hide()
    @plugins.find('.imdone-plugin').hide()
    @plugins.find(".#{plugin.constructor.pluginName}").show()
    @plugins.show()
    @show()

  showRename: (name) ->
    @hide()
    @renameListLabel.text 'Rename '+name
    @listToRename = name
    @renameListField.getModel().setText name
    @renameListField.getModel().selectAll()
    @renameList.show()
    @setHeight(100)
    @show()
    @renameListField.focus()

  getRenameList: ->
    @renameListField.getModel().getText()

  editListName: (name) ->
    @showRename name

  cancelRename: ->
    @hide()

  doListRename: ->
    return unless @listOk @getRenameList()
    @imdoneRepo.renameList @listToRename, @getRenameList()
    @hide()

  showNewList: ->
    @hide()
    @newListField.getModel().setText ''
    @newList.show()
    @setHeight(100)
    @show()
    @newListField.focus()

  getNewList: ->
    @newListField.getModel().getText()

  addList: ->
    @showNewList()

  cancelNewList: ->
    @hide()

  doNewList: ->
    return unless @listOk @getNewList()
    @hide()
    @imdoneRepo.addList(name: @getNewList(), hidden:false)

  listOk: (name) ->
    return true if /^[\w\-]+$/.test(name)
    @error.html('List name can only contain letters, numbers , dashes and underscores')
    false
