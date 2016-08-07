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
      @div outlet: 'productPanel', class: 'block imdone-product-pane row config-container', =>
        @div class: 'col-md-3 product-select-wrapper pull-left', =>
          @h1 'Integrations'
          @subview 'productSelect', new ProductSelectionView
        @div class:'col-md-8 product-detail-wrapper config-container pull-right', =>
          @subview 'productDetail', new ProductDetailView

  initialize: ({@imdoneRepo, @path, @uri, @connectorManager}) ->
    @client = Client.instance

    @connectorManager.on 'product.linked', (product) =>
      @updateConnectorForEdit product
      @productSelect.updateItem product
      @productDetail.setProduct product

    @connectorManager.on 'product.unlinked', (product) =>
      # READY:100 Connector plugin should be removed id:99
      @updateConnectorAfterDisable(product.connector)
      @updateConnectorForEdit product
      @productSelect.updateItem product
      @productDetail.setProduct product

    @connectorManager.on 'project.found', (project) => @showProductPanel project
    @showProductPanel @connectorManager.project if @connectorManager.project

  updateConnectorAfterDisable: (connector) ->
    return unless connector
    @updateConnector connector
    @emitter.emit 'connector.disabled', connector

  show: () ->
    super
    @onAuthenticated() if @client.isAuthenticated()

  onAuthenticated: () ->  @showProductPanel @connectorManager.project if @connectorManager.project

  handleEvents: (@emitter) ->
    if @initialized || !@emitter then return else @initialized = true
    @productSelect.handleEvents @emitter
    @productDetail.handleEvents @emitter

    self = @
    @emitter.on 'product.selected', (product) =>
      @updateConnectorForEdit product
      @productDetail.setProduct product

    @emitter.on 'connector.change', (product) =>
      @connectorManager.saveConnector product.connector, (err, connector) =>
        # TODO:110 Handle errors by unauthenticating if needed and show login with error id:101
        product.connector = connector
        @productSelect.updateItem product

    @emitter.on 'connector.enable', (connector) =>
      @connectorManager.enableConnector connector, (err, updatedConnector) =>
        # TODO:120 Handle errors id:102
        return if err
        @updateConnector updatedConnector
        @emitter.emit 'connector.enabled', updatedConnector

    @emitter.on 'connector.disable', (connector) =>
      @connectorManager.disableConnector connector, (err, updatedConnector) =>
        # TODO:130 Handle errors id:103
        @updateConnectorAfterDisable updatedConnector unless err

    @client.on 'authenticated', => @onAuthenticated()

  updateConnector: (connector) ->
    # BACKLOG:210 This should probable use observer [Data-binding Revolutions with Object.observe() - HTML5 Rocks](http://www.html5rocks.com/en/tutorials/es7/observe/) id:104
    updatedProduct = @productSelect.getProduct connector.name
    updatedProduct.connector = connector
    @productSelect.updateItem updatedProduct
    @productDetail.setProduct updatedProduct

  showProductPanel: (@project)->
    @connectorManager.getProducts (err, products) =>
      return if err
      @productSelect.setItems products
      @productPanel.show()

  updateConnectorForEdit: (product) ->
    _.set product, 'connector', {} unless product.connector
    return unless product.name == 'github' && !_.get(product, 'connector.config.repoURL')
    _.set product, 'connector.config.repoURL', @connectorManager.getGitOrigin() || ''
