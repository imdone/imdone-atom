{$, $$, $$$, View, TextEditorView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
_ = require 'lodash'
util = require 'util'
debug = require 'debug'
config = require '../../config'
log = debug 'imdone-atom:share-tasks-view'
Client = require '../services/imdoneio-client'

module.exports =
class LoginView extends View
  @content: (params) ->
    @div class: "login-container config-container", =>
      @div class: "text-center", =>
        @h1 "Create, update and close GitHub issues from TODO comments in your code with #{config.name}!"
        @h2 "Login or sign up to get started"
      @div outlet: 'spinner', class: 'spinner', style: 'display:none;', =>
        @span class:'loading loading-spinner-small inline-block'

      @div outlet:'loginPanel', class: 'imdone-login-pane form-group', style: 'display:none;', =>
        @div class: 'input input-med inline-block-tight native-key-bindings', =>
          @input type: 'email', outlet: 'emailEditor', placeholder: 'email', class: 'form-control'
        @div class: 'input input-med inline-block-tight native-key-bindings', =>
          @input type:'password', outlet: 'passwordEditor', placeholder: 'password', class: 'form-control'
        @div class:'btn-group btn-group-login inline-block-tight', =>
          @button outlet: 'loginButton', click: 'login', title: 'WHOOSH!', class:'btn btn-primary inline-block-tight', 'LOGIN'
      @h2 "or"
      @a class: 'btn btn-lg btn-success icon icon-mark-github', href:"#{Client.githubAuthUrl}", "Sign up with GitHub"
      # @iframe width: "974", height:"548", src:"https://www.youtube.com/embed/ECIfGmngetU", frameborder:"0", allowfullscreen: true

  initialize: ({@imdoneRepo, @path, @uri}) ->
    @client = Client.instance

  show: () ->
    super
    @showLogin()
    @emailEditor.focus()

  showLogin: () ->
    @loginPanel.css 'display', 'inline-block'

  onAuthenticated: () ->
    delete @authenticating
    @loginPanel.hide()
    @spinner.hide()

  onUnauthenticated: (event) ->
    # BACKLOG: Show login error if present and hide progress
    @showLogin()

  login: () ->
    @authenticating = true
    log 'login:begin'
    @loginPanel.hide()
    @spinner.show()
    email = @emailEditor.val()
    password = @passwordEditor.val()
    @client.authenticate email, password, (err, profile) =>
      @spinner.hide()
      @passwordEditor.val ''
      # TODO: We need to show an error here if service can't be reached or login fails gh:116
      log 'login:end'
      return @showLogin() unless @client.isAuthenticated()
      @onAuthenticated()

  handleEvents: (@emitter) ->
    if @initialized || !@emitter then return else @initialized = true

    self = @
    @emailEditor.on 'keydown', (e) =>
      code = e.keyCode || e.which
      switch code
        when 13 then self.login()
        when 9 then self.passwordEditor.focus()
        else return true
      false

    @passwordEditor.on 'keydown', (e) =>
      code = e.keyCode || e.which
      switch code
        when 13 then self.login()
        when 9 then self.loginButton.focus()
        else return true
      false

    @loginButton.on 'keydown', (e) =>
      code = e.keyCode || e.which
      switch code
        when 13 then self.login()
        when 9 then self.emailEditor.focus()
        else return true
      false

    @emitter.on 'authenticated', => @onAuthenticated()
    @emitter.on 'unauthenticated', => @onUnauthenticated(event)
