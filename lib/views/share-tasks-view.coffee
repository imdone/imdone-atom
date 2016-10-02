{$, $$, $$$, View, TextEditorView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
_ = require 'lodash'
util = require 'util'
debug = require 'debug/browser'
log = debug 'imdone-atom:share-tasks-view'
Client = require '../services/imdoneio-client'
ProductSelectionView = require './product-selection-view'
ProductDetailView = require './product-detail-view'
ProjectSettingsView = require './project-settings-view'
ConnectorManager = require '../services/connector-manager'

module.exports =
class ShareTasksView extends View
  @content: (params) ->
    @div class: "share-tasks-container config-container", =>
      @div outlet: 'spinner', class: 'spinner', style: 'display:none;', =>
        @span class:'loading loading-spinner-small inline-block'
      @subview 'projectSettings', new ProjectSettingsView params
      @div outlet: 'productPanel', class: 'block imdone-product-pane row config-container', style:'display:none;', =>
        @div class: 'product-select-wrapper', =>
          @h1 'TODOBOTs'
          @subview 'productSelect', new ProductSelectionView
        @div class:'product-detail-wrapper', =>
          @subview 'productDetail', new ProductDetailView

  initialize: ({@imdoneRepo, @path, @uri, @connectorManager}) ->
    @client = Client.instance

    @connectorManager.on 'product.linked', (product) =>
      @updateConnectorForEdit product
      @productSelect.updateItem product
      @productDetail.setProduct product

    @connectorManager.on 'product.unlinked', (product) =>
      # READY: Connector plugin should be removed
      @updateConnectorAfterDisable(product.connector)
      @updateConnectorForEdit product
      @productSelect.updateItem product
      @productDetail.setProduct product

    @imdoneRepo.on 'project.found', (project) => @showProductPanel project
    @showProductPanel @imdoneRepo.project if @imdoneRepo.project

  updateConnectorAfterDisable: (connector) ->
    return unless connector
    @updateConnector connector
    @emitter.emit 'connector.disabled', connector

  show: () ->
    super
    @onAuthenticated() if @client.isAuthenticated()

  onAuthenticated: () ->  @showProductPanel @imdoneRepo.project if @imdoneRepo.project

  handleEvents: (@emitter) ->
    if @initialized || !@emitter then return else @initialized = true
    @productSelect.handleEvents @emitter
    @productDetail.handleEvents @emitter
    @projectSettings.handleEvents @emitter

    self = @
    @emitter.on 'product.selected', (product) =>
      @updateConnectorForEdit product
      @productDetail.setProduct product

    @emitter.on 'connector.change', (product) =>
      connector = _.cloneDeep product.connector
      @connectorManager.saveConnector connector, (err, connector) =>
        # TODO: Handle errors by unauthenticating if needed and show login with error
        throw err if err
        product.connector = connector
        @productSelect.updateItem product

    @emitter.on 'connector.enable', (connector) =>
      @connectorManager.enableConnector connector, (err, updatedConnector) =>
        # TODO: Handle errors
        return if err
        @updateConnector updatedConnector
        @emitter.emit 'connector.enabled', updatedConnector

    @emitter.on 'connector.disable', (connector) =>
      @connectorManager.disableConnector connector, (err, updatedConnector) =>
        # TODO: Handle errors
        @updateConnectorAfterDisable updatedConnector unless err

    @client.on 'authenticated', => @onAuthenticated()

  updateConnector: (connector) ->
    # BACKLOG: This should probable use observer [Data-binding Revolutions with Object.observe() - HTML5 Rocks](http://www.html5rocks.com/en/tutorials/es7/observe/)
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
