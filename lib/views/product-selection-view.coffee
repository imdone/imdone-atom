{$, $$, $$$, View} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
util = require 'util'
_ = require 'lodash'
pluginManager = require '../services/plugin-manager'
DEFAULT_CONNECTOR = require '../services/default-connector'

module.exports =
class ProductSelectionView extends View
  initialize: ({@imdoneRepo, @path, @uri}) ->
  @content: (params) ->
    @div =>
      @div outlet: 'productControls'

  populateList: ->
    @productControls.empty()
    @productControls.append @viewForItem(product) for product in @products
    @saveDefaultConnector()

  viewForItem: (product) ->
    plugin = pluginManager.getByProvider product.name
    icon = if plugin then "icon-#{plugin.icon}" else "icon-package"
    $$ ->
      @li class:"integration-product", 'data-name': product.name, =>
        @div =>
          @a class: 'product-link', href:'#', 'data-name': product.name, =>
            @div class:"icon #{icon}"
            @div class:"product-name", product.name
        @div =>
          @label class:'input-label', =>
            @text "OFF "
            @input class:'input-toggle', 'data-name':product.name, type:'checkbox', checked:'checked' if product.isEnabled()
            @input class:'input-toggle', 'data-name':product.name, type:'checkbox' unless product.isEnabled()
            @text " ON"

  # DONE: Add stop using imdone.io with icon-stop id:98
  handleEvents: (@emitter) ->
    return if @initialized || !@emitter
    @initialized = true

    @emitter.on 'project.removed', (project) => @setItems []

    @emitter.on 'product.linked', (product) => @updateItem product

    @emitter.on 'product.unlinked', (product) => @updateItem product

    @emitter.on 'connector.enabled', (connector) =>
      @find(".input-toggle[data-name=#{connector.name}]").prop "checked", true

    @emitter.on 'connector.disabled', (connector) =>
      @find(".input-toggle[data-name=#{connector.name}]").prop "checked", false

    @on 'click', '.product-link', (e) => @selectClosestProduct e

    @on 'click', '.input-toggle', (e) =>
      @selectClosestProduct e
      connector = _.cloneDeep @selected.connector
      connector.name = @selected.name
      if e.target.checked
        if connector.id
          @imdoneRepo.enableConnector connector, (err, updatedConnector) =>
            # TODO: Handle errors id:99
            return if err
            @selected.connector = updatedConnector
            @emitter.emit 'connector.changed', @selected
            @emitter.emit 'connector.enabled', updatedConnector
        else
          @saveConnector connector
      else
        @imdoneRepo.disableConnector connector, (err, updatedConnector) =>
          # TODO: Handle errors id:100
          return unless updatedConnector
          @selected.connector = updatedConnector
          @emitter.emit 'connector.changed', @selected
          @emitter.emit 'connector.disabled', updatedConnector

  selectClosestProduct: (e) ->
    $link = $(e.target).closest '.integration-product'
    name = $link.data('name')
    product = _.find @products, name: name
    @selectProduct product

  saveConnector: (connector, cb) ->
    cb ?= ()->
    @imdoneRepo.saveConnector connector, (err, connector) =>
      # TODO: Handle errors by unauthenticating if needed and show login with error id:101
      cb err if err
      @selected.connector = connector
      @emitter.emit 'connector.changed', @selected
      cb null, connector

  saveDefaultConnector: ->
    return if @defaultConnectorCreated
    return unless @imdoneRepo.isImdoneIOProject()
    product = _.find @products, name: DEFAULT_CONNECTOR.name
    return if product.connector.id
    @defaultConnectorCreated = true
    product.connector.enabled = true
    product.connector.name = DEFAULT_CONNECTOR.name
    _.set product.connector, 'config.rules', DEFAULT_CONNECTOR.config.rules
    @saveConnector product.connector, (err, connector) ->
      return if err
      product.connector.id = connector.id
      detail = "Your default #{connector.name} TODOBOTs have been enabled! Take a look below to see what they do."
      atom.notifications.addInfo "TODOBOTs Enabled!", detail: detail, dismissable: true, icon: 'check'

  setItems: (@products) ->
    @selectProduct @products[0] if @products && @products.length > 0
    @populateList()

  show: ->
    @populateList()
    super()

  updateItem: (item) ->
    for product, i in @items
      if product.name == item.name
        @items[i] = item
    selectedItem = @getSelectedItem()
    itemSelector = "li[data-name=#{selectedItem.name}]"
    @populateList()

  getSelectedItem: -> @selected

  selectProduct: (product) ->
    return unless @emitter
    @emitter.emit 'product.selected', product
    @selected = product

  getProduct: (name) ->  _.find @items, name: name
