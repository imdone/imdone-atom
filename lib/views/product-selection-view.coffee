{$, $$, $$$, View} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
util = require 'util'
_ = require 'lodash'
pluginManager = require '../services/plugin-manager'

module.exports =
class ProductSelectionView extends View
  initialize: ({@imdoneRepo, @path, @uri, @connectorManager}) ->
  @content: (params) -> @div()
  handleEvents: (@emitter) ->
    return if @initialized || !@emitter
    @initialized = true

    @emitter.on 'project.removed', (project) => @setItems []

    @connectorManager.on 'product.linked', (product) => @updateItem product

    @connectorManager.on 'product.unlinked', (product) => @updateItem product

    @emitter.on 'connector.enabled', (connector) =>
      @find("[data-name=#{connector.name}] .icon").removeClass("text-warning text-info").addClass("text-success")

    @emitter.on 'connector.disabled', (connector) =>
      @find("[data-name=#{connector.name}] .icon").removeClass("text-success text-info").addClass("text-warning")

    @on 'click', (e) =>
      $link = $(e.target).closest 'a'
      name = $link.data('name')
      product = _.find @products, name: name
      @selectProduct product

  setItems: (@products) ->
    @selectProduct @products[0] if @products && @products.length > 0
    @populateList()

  populateList: ->
    @empty()
    @append @viewForItem(product) for product in @products

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
    @selected = product
    @emitter.emit 'product.selected', product if @emitter

  getProduct: (name) ->
    _ = require 'lodash'
    _.find @items, name: name

  viewForItem: (product) ->
    plugin = pluginManager.getByProvider product.name
    icon = if plugin then "icon-#{plugin.icon}" else "icon-package"
    text = if product.isEnabled() then 'text-success' else if product.isLinked() then 'text-warning' else 'text-info'
    $$ ->
      @li class:"integration-product", 'data-name': product.name, =>
        @a href:'#', 'data-name': product.name, =>
          @div class:"icon #{icon} #{text}"
          @div class:"product-name", product.name
