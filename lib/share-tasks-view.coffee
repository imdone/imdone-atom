{$, $$, $$$, View, TextEditorView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
util = require 'util'
Client = require './services/imdoneio-client'

module.exports =
class ShareTasksView extends View
  @content: (params) ->
    @div class: "share-tasks-container", =>
      @div outlet:'loginPanel', class: 'block imdone-login-pane', style: 'display:none;', =>
        @div class: 'input-med', =>
          @subview 'emailEditor', new TextEditorView(mini: true, placeholderText: 'email')
        @div class: 'input-med', =>
          @subview 'passwordEditor', new TextEditorView(mini: true, placeholderText: 'password')
        @div class:'btn-group btn-group-login', =>
          @button outlet: 'loginButton', click: 'login', title: 'WHOOSH!', class:'btn btn-primary inline-block-tight', 'LOGIN'
        @div class:'block', =>
          @span "or "
          @a href:"#{Client.signUpUrl}", "sign up"

  initialize: ->
    @initPasswordField()
    @handleEvents()

  constructor: ({@imdoneRepo, @path, @uri}) ->
    super
    @emitter = new Emitter
    @client = new Client

  show: () ->
    super
    if @client.isAuthenticated()
    else
      @loginPanel.show()
      @emailEditor.focus()

  initPasswordField: () ->
    # [Password fields when using EditorView subview - packages - Atom Discussion](https://discuss.atom.io/t/password-fields-when-using-editorview-subview/11061/7)
    passwordElement = $(@passwordEditor.element.rootElement)
    passwordElement.find('div.lines').addClass('password-lines')
    @passwordEditor.getModel().onDidChange =>
      string = @passwordEditor.getModel().getText().split('').map(->
        '*'
      ).join ''

      passwordElement.find('#password-style').remove()
      passwordElement.append('<style id="password-style">.password-lines .line span.text:before {content:"' + string + '";}</style>')

  login: () ->
    email = @emailEditor.getModel().getText()
    password = @passwordEditor.getModel().getText()
    @client.authenticate email, password, () =>
      @passwordEditor.getModel().setText ''
      if @client.isAuthenticated()
        @loginPanel.hide()

  handleEvents: () ->
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
