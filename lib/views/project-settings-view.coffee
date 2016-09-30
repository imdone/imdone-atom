{$, $$, $$$, View, TextEditorView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
_ = require 'lodash'
util = require 'util'
debug = require 'debug/browser'
log = debug 'imdone-atom:project-settings-view'
Client = require '../services/imdoneio-client'
require('bootstrap-tokenfield') $

module.exports =
class ProjectSettingsView extends View
  @content: (params) ->
    @div class: "config-container", =>
      @div outlet:'disabledProject', class:'block text-center' , =>
        @h1 "Welcome to imdone.io!"
        @h3 "Create and Update GitHub issues from TODO comments in your code!"
        @button click:'enableProject', class:'btn btn-lg btn-success', "Use imdone.io with this project"
      @div outlet: 'settingsPanel', style:'display:none;', =>
        # @h1 "Project Settings"

        # READY: Add config view here
        # @h1 "Configuration (.imdone/config.json)"

      @div outlet:'enabledProject', class:'block text-center' , style:'display:none;', =>
        @button click:'disableProject', class:'btn btn-small btn-error', "Stop using imdone.io with this project"


  show: ->
    super()

  initialize: ({@imdoneRepo, @path, @uri, @connectorManager}) ->
    @client = Client.instance

  handleEvents: (@emitter) ->
    if @initialized || !@emitter then return else @initialized = true

    @imdoneRepo.on 'project.found', (project) =>
      @settingsPanel.show()
      @disabledProject.hide()
      @enabledProject.show()

    @imdoneRepo.on 'project.removed', (project) =>
      @settingsPanel.hide()
      @enabledProject.hide()
      @disabledProject.show()

  enableProject: (e) ->
    @emitter.emit 'error.hide'
    @client.createProject @imdoneRepo, (err, project) =>
      # DONE: If err=TOO_MANY_PROJECTS_ERROR then show a message!!!
      if _.get(err,'response.body.name') == "TOO_MANY_PROJECTS_ERROR"
        @emitter.emit 'error', @$tooManyProjectsMsg()
        @disabledProject.show()
      return if err
      return unless project
      @imdoneRepo.checkForIIOProject()

  $tooManyProjectsMsg: ->
    projectUrl = Client.projectsUrl
    $$ ->
      @p =>
        @span "You'll have to "
        @a href:"#{Client.plansUrl}", "upgrade"
        @span " or "
        @a href:"#{Client.projectsUrl}", "disable/remove projects"
        @span " before adding another."

  disableProject: (e) ->
    # DOING: implement disableProject
    @imdoneRepo.disableProject() if window.confirm "Do you really want to stop using imdone.io with #{@imdoneRepo.getProjectName()}?"
