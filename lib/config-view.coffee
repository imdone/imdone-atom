{$, $$, $$$, View, TextEditorView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'

module.exports =
class ConfigView extends View

  @content: ->
    @div class:'imdone-config-container', =>
      @div outlet: 'renameList', class:'rename-list config-panel', =>
        @h2 =>
          @span outlet:'renameListLabel'
        @div class: 'block', =>
          @div class: 'input-small', =>
            @subview 'renameListField', new TextEditorView(mini: true)
          @button click: 'cancelRename', class:'inline-block-tight btn', 'Cancel'
          @button click: 'doListRename', class:'inline-block-tight btn', 'Save'
      @div outlet: 'newList', class:'new-list config-panel', =>
        @h2 'New List'
        @div class: 'block', =>
          @div class: 'input-small', =>
            @subview 'newListField', new TextEditorView(mini: true)
          @button click: 'cancelNewList', class:'inline-block-tight btn', 'Cancel'
          @button click: 'doNewList', class:'inline-block-tight btn', 'Save'
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

  show: ->
    @emitter.emit 'config.open'
    @addClass 'open'

  hide: ->
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
    @imdoneRepo.addList(name: @getNewList(), hidden:false)
    @hide()
