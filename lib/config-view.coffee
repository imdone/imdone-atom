{$, $$, $$$, View, TextEditorView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'

module.exports =
class ConfigView extends View

  @content: ->
    @div class:'imdone-config-container', =>
      @div outlet: 'renameList', class:'rename-list', =>
        @h2 =>
          @span outlet:'renameListLabel'
        @div class: 'block', =>
          @div class: 'input-small', =>
            @subview 'listNameField', new TextEditorView(mini: true)
          @button click: 'cancelRename', class:'inline-block-tight btn', 'Cancel'
          @button click: 'doListRename', class:'inline-block-tight btn', 'Save'

  initialize: ({@imdoneRepo, @path, @uri}) ->
    @emitter = new Emitter

  showRename: (name) ->
    @renameListLabel.text 'Rename '+name
    @listToRename = name
    @listNameField.getModel().setText name
    @listNameField.getModel().selectAll()
    @listNameField.focus()
    @renameList.show()
    @show()

  getListName: ->
    @listNameField.getModel().getText()

  show: ->
    @emitter.emit 'config.open'
    @toggleClass 'open'

  hide: ->
    @toggleClass 'open'
    @emitter.emit 'config.close'

  editListName: (name) ->
    @showRename name

  cancelRename: ->
    @hide()

  doListRename: ->
    @imdoneRepo.renameList @listToRename, @getListName()
    @hide()
