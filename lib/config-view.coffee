{$, $$, $$$, View, TextEditorView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'

module.exports =
class ConfigView extends View

  @content: ->
    @div class:'imdone-config-container', =>
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
      # #BACKLOG:10 Add config view here

  initialize: ({@imdoneRepo, @path, @uri}) ->
    @emitter = new Emitter
    @handleEvents()

  handleEvents: ->
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

  isOpen: ->
    @hasClass 'open'

  show: ->
    unless @isOpen()
      @emitter.emit 'config.open'
      @addClass 'open'

  hide: ->
    if @isOpen()
      @error.empty()
      @find('.config-panel').hide()
      @removeClass 'open'
      @emitter.emit 'config.close'

  showRename: (name) ->
    @hide()
    @renameListLabel.text 'Rename '+name
    @listToRename = name
    @renameListField.getModel().setText name
    @renameListField.getModel().selectAll()
    @renameList.show()
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
    @imdoneRepo.addList(name: @getNewList(), hidden:false)
    @hide()

  listOk: (name) ->
    return true if /^[\w\-]+$/.test(name)
    @error.html('List name can only contain letters, numbers , dashes and underscores')
    false
