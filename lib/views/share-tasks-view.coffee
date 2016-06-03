{$, $$, $$$, View, TextEditorView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
_ = require 'lodash'
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
      @div outlet: 'productPanel', class: 'block imdone-product-pane row config-container', style: 'display:none;', =>
        @div class: 'col-md-3 product-select-wrapper pull-left', =>
          @subview 'productSelect', new ProductSelectionView
        @div class:'col-md-9 product-detail-wrapper config-container pull-right', =>
          @subview 'productDetail', new ProductDetailView

  initialize: ({@imdoneRepo, @path, @uri, @connectorManager}) ->
    @client = Client.instance
    @initPasswordField()

    @connectorManager.on 'product.linked', (product) =>
      @updateConnectorForEdit product
      @productSelect.updateItem product
      @productDetail.setProduct product

    @connectorManager.on 'product.unlinked', (product) =>
      # READY:0 Connector plugin should be removed id:542
      @updateConnectorAfterDisable(product.connector)
      @updateConnectorForEdit product
      @productSelect.updateItem product
      @productDetail.setProduct product

    @connectorManager.on 'project.found', (project) => @projectFound project
    @projectFound @connectorManager.project if @connectorManager.project

  updateConnectorAfterDisable: (connector) ->
    return unless connector
    @updateConnector connector
    @emitter.emit 'connector.disabled', connector

  show: () ->
    super
    return @onAuthenticated() if @client.isAuthenticated()
    @loginPanel.show()
    @emailEditor.focus()

  onAuthenticated: () ->
    @loginPanel.hide()

  projectFound: (@project) ->
    @showProductPanel()

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
      # TODO:10 We need to show an error here if login fails because service can't be reached or if login fails id:629
      log 'login:end'
      return @loginPanel.show() unless @client.isAuthenticated()
      @onAuthenticated()

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
      @updateConnectorForEdit product
      @productDetail.setProduct product

    @emitter.on 'connector.change', (product) =>
      @connectorManager.saveConnector product.connector, (err, connector) =>
        # TODO:40 Handle errors by unauthenticating if needed and show login with error id:630
        product.connector = connector
        @productSelect.updateItem product

    @emitter.on 'connector.enable', (connector) =>
      @connectorManager.enableConnector connector, (err, updatedConnector) =>
        # TODO:30 Handle errors id:631
        return if err
        @updateConnector updatedConnector
        @emitter.emit 'connector.enabled', updatedConnector

    @emitter.on 'connector.disable', (connector) =>
      @connectorManager.disableConnector connector, (err, updatedConnector) =>
        # TODO:20 Handle errors id:632
        @updateConnectorAfterDisable updatedConnector unless err

    @client.on 'authenticated', => @onAuthenticated()

  updateConnector: (connector) ->
    # BACKLOG:30 This should probable use observer [Data-binding Revolutions with Object.observe() - HTML5 Rocks](http://www.html5rocks.com/en/tutorials/es7/observe/) id:633
    updatedProduct = @productSelect.getProduct connector.name
    updatedProduct.connector = connector
    @productSelect.updateItem updatedProduct
    @productDetail.setProduct updatedProduct

  showProductPanel: ->
    @connectorManager.getProducts (err, products) =>
      return if err
      @productSelect.setItems products
      @productPanel.show()

  updateConnectorForEdit: (product) ->
    _.set product, 'connector', {} unless product.connector
    return unless product.name == 'github' && !_.get(product, 'connector.config.repoURL')
    _.set product, 'connector.config.repoURL', @connectorManager.getGitOrigin()
