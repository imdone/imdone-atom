{$, $$, $$$, View} = require 'atom-space-pen-views'
_ = require 'lodash'
util = require 'util'

module.exports =
class ProductDetailView extends View
  initialize: ({@imdoneRepo, @path, @uri, @connectorManager}) ->

  updateConnectorForEdit: (product) ->
    _.set product, 'connector', {} unless product.connector
    return unless product.name == 'github' && !_.get(product, 'connector.config.repoURL')
    _.set product, 'connector.config.repoURL', @connectorManager.getGitOrigin() || ''

  handleEvents: (@emitter)->
    if @initialized || !@emitter then return else @initialized = true
    # @on 'click', '#create-tasks', =>
    #   @emitter.emit 'tasks.create', @product.name
    @emitter.on 'project.removed', (project) =>
      @$configEditor.empty()
      @configEditor.destroy() if @configEditor
      delete @product

    @emitter.on 'product.selected', (product) =>
      return unless product
      @updateConnectorForEdit product
      @setProduct product
      @emitter.emit 'connector.enabled', product.connector if product.isEnabled()

    @connectorManager.on 'product.linked', (product) =>
      return unless product
      @updateConnectorForEdit product
      @setProduct product

    @connectorManager.on 'product.unlinked', (product) =>
      return unless product
      # READY: Connector plugin should be removed
      @updateConnectorForEdit product
      @setProduct product

    @on 'click', '.enable-btn', =>
      return if @product.isEnabled()
      # READY: Connector plugin should be added
      if @product.connector.id
        @connectorManager.enableConnector @product.connector, (err, updatedConnector) =>
          # TODO: Handle errors
          return if err
          @product.connector = updatedConnector
          @setProduct @product
          @emitter.emit 'connector.enabled', updatedConnector
      @product.connector.enabled = true
      @emitChange()

    @on 'click', '.disable-btn', =>
      return unless @product.isEnabled()
      # READY: Connector plugin should be removed
      @connectorManager.disableConnector @product.connector, (err, updatedConnector) =>
        # TODO: Handle errors
        return unless updatedConnector
        @product.connector = updatedConnector
        @setProduct @product
        @emitter.emit 'connector.disabled', updatedConnector

  @content: (params) ->
    require 'json-editor'
    @div class: 'product-detail-view-content config-container', =>
      @div outlet: '$detail'
      @div class: 'json-editor-container', =>
        @div outlet: '$configEditor', class: 'json-editor native-key-bindings'

  setProduct: (@product)->
    return unless @product && @product.name
    @$detail.html @getDetail(@product)
    @$configEditor.empty()
    return unless @product.linked
    if @product.isEnabled() then @$configEditor.show() else @$configEditor.hide()
    @createEditor()

  createEditor: ->
    options =
      schema: @product.schemas.config # TODO: Rule schemas to be set by GET /projects/ :projectId/products +rules-workflow
      startval: @product.connector.config # TODO: Rule values to be set by GET /projects/ :projectId/products +rules
      theme: 'bootstrap3'
      required_by_default: true
      disable_edit_json: true
      disable_properties: true
      disable_collapse: true
      disable_array_delete_last_row: true
      disable_array_delete_all_rows: true

    # TODO: Add provider configurations before creating editor
    @configEditor.destroy() if @configEditor
    @configEditor = new JSONEditor @$configEditor.get(0), options
    @configEditor.on 'change', => @emitChange()

  emitChange: ->
    editorVal = @configEditor.getValue()
    currentVal =  _.get @product, 'connector.config'
    return unless @product.isEnabled()
    return if _.isEqual editorVal, currentVal
    _.set @product, 'connector.config', editorVal
    _.set @product, 'connector.name', @product.name unless _.get @product, "connector.name"
    connector = _.cloneDeep @product.connector
    @connectorManager.saveConnector connector, (err, connector) =>
      # TODO: Handle errors by unauthenticating if needed and show login with error
      throw err if err
      @product.connector = connector
      @setProduct @product
      @emitter.emit 'connector.changed', @product

  # READY: Add enable checkbox and take appropriate actions on check/uncheck +urgent
  # READY: When unlinked disable all connectors (In API) +urgent
  getDetail: (product) ->
    $$ ->
      @h1 "#{product.name}"
      # TODO: This will have to be upadted on an event sent with pusher
      @div class:'block', =>
        if product.isLinked()
          @div class:'btn-group', =>
            selected = if product.isEnabled() then " selected" else ""
            @button class:"enable-btn btn#{selected}", 'ON'
            selected = unless product.isEnabled() then " selected" else ""
            @button class:"disable-btn btn#{selected}", 'OFF'
          @a href:product.logout, class:'btn icon icon-log-out inline-block-tight', "unlink your #{product.name} account"
          # @button id:'create-tasks', class:'btn icon icon icon-cloud-upload inline-block-tight', "create #{product.entity}s on #{product.name}"
        else
          @a href:product.login, class:'btn icon icon-log-in inline-block-tight', "link your #{product.name} account"
