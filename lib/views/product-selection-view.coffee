{$, $$, $$$, View} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
util = require 'util'
_ = require 'lodash'
pluginManager = require '../services/plugin-manager'

module.exports =
class ProductSelectionView extends View
  initialize: ({@imdoneRepo, @path, @uri, @connectorManager}) ->
  @content: (params) ->
    @div =>
      @div outlet: 'productControls'

  populateList: ->
    @productControls.empty()
    @productControls.append @viewForItem(product) for product in @products

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

  # DOING: Add stop using imdone.io with icon-stop
  handleEvents: (@emitter) ->
    return if @initialized || !@emitter
    @initialized = true

    @emitter.on 'project.removed', (project) => @setItems []

    @connectorManager.on 'product.linked', (product) => @updateItem product

    @connectorManager.on 'product.unlinked', (product) => @updateItem product

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
          @connectorManager.enableConnector connector, (err, updatedConnector) =>
            # TODO: Handle errors
            return if err
            @selected.connector = updatedConnector
            @emitter.emit 'connector.changed', @selected
            @emitter.emit 'connector.enabled', updatedConnector
        else
          @connectorManager.saveConnector connector, (err, connector) =>
            # TODO: Handle errors by unauthenticating if needed and show login with error
            throw err if err
            @selected.connector = connector
            @emitter.emit 'connector.changed', @selected
      else
        @connectorManager.disableConnector connector, (err, updatedConnector) =>
          # TODO: Handle errors
          return unless updatedConnector
          @selected.connector = updatedConnector
          @emitter.emit 'connector.changed', @selected
          @emitter.emit 'connector.disabled', updatedConnector

  selectClosestProduct: (e) ->
    $link = $(e.target).closest '.integration-product'
    name = $link.data('name')
    product = _.find @products, name: name
    @selectProduct product

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
