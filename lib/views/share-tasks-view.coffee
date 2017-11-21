{$, $$, $$$, View, TextEditorView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
_ = require 'lodash'
util = require 'util'
debug = require 'debug'
log = debug 'imdone-atom:share-tasks-view'
ProjectSettingsView = require './project-settings-view'

module.exports =
class ShareTasksView extends View
  @content: (params) ->
    @div class: "share-tasks-container config-container", =>
      @div outlet: 'spinner', class: 'spinner', style: 'display:none;', =>
        @span class:'loading loading-spinner-small inline-block'
      @subview 'projectSettings', new ProjectSettingsView params

  initialize: ({@imdoneRepo, @path, @uri}) ->
    @show()

  handleEvents: (@emitter) ->
    if @initialized || !@emitter then return else @initialized = true
    @projectSettings.handleEvents @emitter
