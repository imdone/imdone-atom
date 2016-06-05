{$, $$, $$$, View, TextEditorView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'

module.exports =
class BottomView extends View
  constructor: ({@imdoneRepo, @path, @uri}) ->
    super

  @content: (params) ->
    ShareTasksView = require './share-tasks-view'
    @div class:'imdone-config-container hidden', =>
      @div outlet: 'resizer', class:'split-handle-y'
      @div outlet: 'closeButton', class:'close-button', =>
        @raw '&times;'
      @div outlet: 'error', class:'text-error'
      @div outlet: 'shareTasks', class:'share-tasks config-panel', =>
        @subview 'shareTasksView', new ShareTasksView(params)
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
      # #BACKLOG:180 Add config view here id:601

  handleEvents: (@emitter)->
    if @initialized || !@emitter then return else @initialized = true
    @shareTasksView.handleEvents @emitter

    # #DONE:120 Make resizable when open [Edit fiddle - JSFiddle](http://jsfiddle.net/3jMQD/614/) id:602
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
      switch code
        when 13 then @doNewList()
        when 27 then @cancelNewList()
      true

    @renameListField.on 'keyup', (e) =>
      code = e.keyCode || e.which
      switch code
        when 13 then @doListRename()
        when 27 then @cancelRename()
      true

    @imdoneRepo.on 'list.modified', (list) =>
      @hide()

    @closeButton.on 'click', =>
      @hide()

    # TODO:100 This belongs in bottomView +refactor id:603
    @emitter.on 'list.new', => @showNewList()

    # TODO:90 This belongs in bottomView +refactor id:513
    @emitter.on 'share', => @showShare()


  isOpen: ->
    @hasClass 'open'

  show: ->
    unless @isOpen()
      @emitter.emit 'config.open'
      @addClass 'open'
      @removeClass 'hidden'

  hide: ->
    @find('.config-panel').hide()
    if @isOpen()
      @error.empty()
      @removeClass 'open'
      @addClass 'hidden'
      @css 'height', ''
      @emitter.emit 'config.close'

  setHeight: (px) ->
    @height(px)
    @emitter.emit 'resize.change', px

  addPlugin: (plugin) ->
    pluginView = plugin.getView()
    pluginView.addClass "imdone-plugin #{plugin.constructor.pluginName}"
    pluginView.appendTo @plugins
    # plugin.on 'view.show', => @showPlugin plugin

  removePlugin: (plugin) ->
    plugin.getView().remove()

  showPlugin: (plugin) ->
    @hide()
    @plugins.find('.imdone-plugin').hide()
    @plugins.find(".#{plugin.constructor.pluginName}").show()
    @plugins.show()
    @show()

  showShare: () ->
    @hide()
    @shareTasks.show () => @shareTasksView.show()
    @setHeight(500)
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
