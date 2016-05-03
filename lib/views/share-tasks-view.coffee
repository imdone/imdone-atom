{$, $$, $$$, View, TextEditorView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
util = require 'util'
debug = require 'debug/browser'
log = debug 'imdone-atom:share-tasks-view'
Client = require '../services/imdoneio-client'
ProductSelectionView = require './product-selection-view'
ProductDetailView = require './product-detail-view'
ConnectorManager = require '../services/connector-manager'

module.exports =
class ShareTasksView extends View
  @content: (params) ->
    @div class: "share-tasks-container config-container", =>
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
      @div outlet: 'productPanel', class: 'block imdone-product-pane row config-container', style: 'display:none;', =>
        @div class: 'col-md-4 product-select-wrapper', =>
          @subview 'productSelect', new ProductSelectionView
        @div class:'col-md-7 product-detail-wrapper config-container', =>
          @subview 'productDetail', new ProductDetailView

  initialize: ({@imdoneRepo, @path, @uri}) ->
    @client = Client.instance
    @connectorManager = new ConnectorManager @imdoneRepo
    @initPasswordField()

  show: () ->
    super
    if @client.isAuthenticated()
      @showProductPanel()
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
    log 'login:begin'
    @loginPanel.hide()
    @spinner.show()
    email = @emailEditor.getModel().getText()
    password = @passwordEditor.getModel().getText()
    @client.authenticate email, password, (err, profile) =>
      @spinner.hide()
      @passwordEditor.getModel().setText ''
      # DOING:0 We need to show an error here is login fails because service can't be reached or if login fails
      log 'login:end'
      return @loginPanel.show() unless @client.isAuthenticated()
      @showProductPanel()

  handleEvents: (@emitter) ->
    if @initialized || !@emitter then return else @initialized = true
    @productSelect.handleEvents @emitter
    @productDetail.handleEvents @emitter

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

    @emitter.on 'product.selected', (product) =>
      console.log product
      @productDetail.setProduct product

    @emitter.on 'connector.change', (product) =>
      @connectorManager.saveConnector product

    @client.on 'product.linked', (product) => @productSelect.updateItem product
    @client.on 'product.unlinked', (product) => @productSelect.updateItem product

  showProductPanel: ->
    @connectorManager.getConnectors (err, connectors) =>
      return if err
      @productSelect.setItems connectors
      @productPanel.show()
