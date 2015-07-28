{$, $$, $$$, View} = require 'atom-space-pen-views'
{Emitter} = require 'atom'

module.exports =
class ConfigView extends View

  @content: ->
    @div class:'imdone-config-container', =>
      @div outlet: 'renameList', class:'rename-list'

  initialize: ({@imdoneRepo, @path, @uri}) ->
    @emitter = new Emitter

  showRename: ->
    @renameList.show()
    @show()

  show: ->
    @toggleClass 'open'
    @emitter.emit 'config.open'

  editListName: (name) ->
    @showRename()
