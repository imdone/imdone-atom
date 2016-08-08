{$, $$, $$$, View, TextEditorView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
_ = require 'lodash'
util = require 'util'
debug = require 'debug/browser'
log = debug 'imdone-atom:project-settings-view'
Client = require '../services/imdoneio-client'
require('bootstrap-tokenfield') $

module.exports =
class TeamSettingsView extends View
  @content: (params) ->
    @div class: "config-container", =>
      @div outlet: 'settingsPanel', class: 'block imdone-team-settings-pane row config-container col-md-6', =>
        @h1 "Team Settings"
        @div class: 'form-group native-key-bindings', =>
          @label for: 'project-invites', title:"Make it a party", 'Invite people to the team (or revoke an invite)'
          @input outlet:'projectInvites', type:'email', class:'form-control', id:'project-invites', placeholder:'Invite by email'
        @div class: 'form-group', =>
          @label for: 'project-members', title:'They must have moved on.', 'Remove teammates'
          @input type:'email', class:'form-control', id:'project-members'
        @div class: 'form-group', =>
          @label for: 'project-admins', title:"Don't be a SPOF!", 'Convert a teammate to admin'
          @input type:'text', class:'form-control', id:'project-admins', placeholder:'Start typing a teammates name'
      @div outlet: 'configPanel', class: 'block imdone-project-config-pane row config-container col-md-6', =>
        # BACKLOG:10 Add config view here
        # @h1 "Configuration (.imdone/config.json)"


  show: ->
    super()
    @projectInvites.siblings('input.token-input').focus()

  initialize: ({@imdoneRepo, @path, @uri, @connectorManager}) ->
    @client = Client.instance
    @projectInvites.on 'tokenfield:createtoken', (e) ->
      currentTokens = (token.value for token in $(@).tokenfield "getTokens")
      email = e.attrs.value
      return e.preventDefault() if email in currentTokens or not /\S+@\S+\.\S+/.test email

    @projectInvites.on 'tokenfield:createdtoken', (e) ->
      
    @projectInvites.on 'tokenfield:edittoken', (e) ->

    @projectInvites.on 'tokenfield:removedtoken', (e) ->
      console.log "Token removed! Token value was: #{e.attrs.value}"

    @projectInvites.tokenfield minWidth: 120, inputType: 'email'

  handleEvents: (@emitter) ->
    if @initialized || !@emitter then return else @initialized = true
