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
      @div class: 'block imdone-team-settings-pane config-container', =>
        @div outlet:'disabledProject', class:'block' , =>
          @button click:'enableProject', class:'btn btn-lg btn-success', "Use imdone.io with this project"
        @div outlet: 'settingsPanel', style:'display:none;', =>
          @h1 "Project Settings"

          @h2 "Project Team"
          @div class: 'form-group native-key-bindings', =>
            @label for: 'project-invites', title:"Make it a party", 'Invite people to the team (or revoke an invite)'
            @input outlet:'projectInvites', type:'email', class:'form-control', id:'project-invites', placeholder:'Invite by email'
          @div class: 'form-group', =>
            @label for: 'project-members', title:'They must have moved on.', 'Remove teammates'
            @input type:'email', class:'form-control', id:'project-members'
          @div class: 'form-group', =>
            @label for: 'project-admins', title:"Don't be a SPOF!", 'Convert a teammate to admin'
            @input type:'text', class:'form-control', id:'project-admins', placeholder:'Start typing a teammates name'

          # READY:0 Add config view here githubClosed:true
          # @h1 "Configuration (.imdone/config.json)"
        @div outlet:'enabledProject', class:'block' , style:'display:none;', =>
          @button click:'disableProject', class:'btn btn-small btn-error pull-right', "Stop using imdone.io with this project"


  show: ->
    super()
    @projectInvites.siblings('input.token-input').focus()

  initialize: ({@imdoneRepo, @path, @uri, @connectorManager}) ->
    @client = Client.instance
    @projectInvites.tokenfield minWidth: 120, inputType: 'email'

  handleEvents: (@emitter) ->
    if @initialized || !@emitter then return else @initialized = true

    @projectInvites.on 'tokenfield:createtoken', (e) ->
      currentTokens = (token.value for token in $(@).tokenfield "getTokens")
      email = e.attrs.value
      return e.preventDefault() if email in currentTokens or not /\S+@\S+\.\S+/.test email

    @projectInvites.on 'tokenfield:createdtoken', (e) ->

    @projectInvites.on 'tokenfield:edittoken', (e) ->

    @projectInvites.on 'tokenfield:removedtoken', (e) ->
      console.log "Token removed! Token value was: #{e.attrs.value}"

    @imdoneRepo.on 'project.found', (project) =>
      @settingsPanel.show()
      @disabledProject.hide()
      @enabledProject.show()

    @imdoneRepo.on 'project.removed', (project) =>
      @settingsPanel.hide()
      @enabledProject.hide()
      @disabledProject.show()

  enableProject: (e) ->
    @client.createProject @imdoneRepo, (err, project) =>
      # DONE: If err=TOO_MANY_PROJECTS_ERROR then show a message!!!
      if _.get(err,'response.body.name') == "TOO_MANY_PROJECTS_ERROR"
        @emitter.emit 'error', @$tooManyProjectsMsg()
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
    # DOING:30 implement disableProject
    @imdoneRepo.disableProject() if window.confirm "Do you really want to stop using imdone.io with #{@imdoneRepo.getProjectName()}?"
