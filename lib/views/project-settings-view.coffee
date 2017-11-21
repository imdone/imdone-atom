{$, $$, $$$, View, TextEditorView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
shell = require 'shell'
_ = require 'lodash'
util = require 'util'
debug = require 'debug'
config = require '../../config'
log = debug 'imdone-atom:project-settings-view'

module.exports =
class ProjectSettingsView extends View
  @content: (params) ->
    @div =>
      @div outlet:'disabledProject', class:'block text-center' , style:'display:none;', =>
        @h1 "Welcome to #{config.name}!"
        @h3 "Create and Update GitHub issues from TODO comments in your code!"
        @button outlet:'enableProjectBtn', click:'enableProject', class:'btn btn-lg btn-success', "Use #{config.name} with this project"
        @div outlet:'progressContainer', class:'block', style:'display:none;', =>
          @progress outlet:'progress', class:'inline-block', max:'100'
          @div outlet: 'progressValue', class: 'inline-block'
          @div class: 'block', =>
            @span outlet:'progressText'
      @div outlet: 'settingsPanel', style:'display:none;', =>
        # @h1 "Project Settings"


        # @h1 "Configuration (.imdone/config.json)"

  initialize: ({@imdoneRepo, @path, @uri}) ->
    @disabledProject.show() unless @imdoneRepo.isImdoneIOProject()

  handleEvents: (@emitter) ->
    if @initialized || !@emitter then return else @initialized = true
    @emitter.on 'sync.percent', (val) =>
      process.nextTick => @updatePercent val

    @emitter.on 'project.found', (project) =>
      @updateProgress 0
      @settingsPanel.show()
      @disabledProject.hide()

    @emitter.on 'project.removed', (project) =>
      @settingsPanel.hide()
      @enableProjectBtn.show()
      @disabledProject.show()

  updateProgress: (n) ->
    return @progressContainer.hide() if n == 0
    n ?= ''
    @progressText.html "Syncing #{n} Comments.  Please wait..."
    @progress.attr 'value', null
    @progressValue.html ''
    @progressContainer.show()

  updatePercent: (val) ->
    @progress.attr 'value', val
    @progressValue.html "#{val}%"

  enableProject: (e) -> shell.openExternal "https://imdone.io/app"

  tooManyProjectsMsg: ->
    """
    Too many projects
    ----
    You'll have to [upgrade](#{@imdoneRepo.plansUrl}) or [disable/remove projects](#{@imdoneRepo.projectsUrl}) before adding
    another project.
    """
