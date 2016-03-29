{$, $$, $$$, View, TextEditorView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
util = require 'util'
Client = require './services/imdoneio-client'

module.exports =
class ShareTasksView extends View
  @content: (params) ->
    @div class: "share-tasks-container", =>
      @div outlet: 'spinner', class: 'spinner', style: 'display:none;', =>
        @span class:'loading loading-spinner-small inline-block'
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
      @div outlet: 'integrationPanel', class: 'block imdone-integration-pane', style: 'display:none;'
      @div outlet: 'productPanel', class: 'block imdone-product-pane', style: 'display:none;'

  initialize: ({@imdoneRepo, @path, @uri}) ->
    @emitter = new Emitter
    @client = new Client
    @initPasswordField()
    @handleEvents()

  show: () ->
    super
    if @client.isAuthenticated()
      @emitter.emit 'authentic'
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
    @loginPanel.hide()
    @spinner.show()
    email = @emailEditor.getModel().getText()
    password = @passwordEditor.getModel().getText()
    @client.authenticate email, password, () =>
      @spinner.hide()
      @passwordEditor.getModel().setText ''
      return @loginPanel.show() unless @client.isAuthenticated()
      @emitter.emit 'authentic'

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

    @emitter.on 'authentic', (e) =>
      @showProductPanel()

  showProductPanel: ->
    @spinner.show()
    @client.getProducts (err, products) =>
      return if err
      @spinner.hide()
      @productPanel.empty().show().append (@getProduct product for product in products)

  getProduct: (product) ->
    $$ ->
      @li "#{product.name}"
