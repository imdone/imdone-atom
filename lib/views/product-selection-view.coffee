{$, $$, $$$, View} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
util = require 'util'
_ = require 'lodash'
pluginManager = require '../services/plugin-manager'
DEFAULT_CONNECTORS = require '../services/default-connectors'

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
    icon = if plugin then "icon-#{plugin.icon}" else "icon-server"
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
            # TODO: Handle errors id:102
            return if err
            @selected.connector = updatedConnector
            @emitter.emit 'connector.changed', @selected
            @emitter.emit 'connector.enabled', updatedConnector
        else
          @saveConnector connector
      else
        @imdoneRepo.disableConnector connector, (err, updatedConnector) =>
          # TODO: Handle errors id:103
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
      cb err if err
      cb null, connector unless @selected
      @selected.connector = connector
      @emitter.emit 'connector.changed', @selected
      cb null, connector

  saveDefaultConnector: ->
    return if @defaultConnectorCreated
    return unless @imdoneRepo.isImdoneIOProject()
    for defaultConnector in DEFAULT_CONNECTORS
      return unless @imdoneRepo.isImdoneIOProject()
      @defaultConnectorCreated = true
      product = _.find @products, name: defaultConnector.name
      continue unless product
      _.set product, 'connector.config', defaultConnector.config unless product.connector && product.connector.config
      continue unless product.connector
      continue if product.connector.id
      product.connector.enabled ?= defaultConnector.enabled
      product.connector.name = product.name
      @saveConnector product.connector, (err, connector) ->
        return if err
        product.connector.id = connector.id
        info = _.get(defaultConnector,'msg.info') || "#{connector.name} connector enabled!"
        detail = _.get(defaultConnector, 'msg.detail') || "Your default #{connector.name} rules have been enabled! Take a look below to see what they do."
        atom.notifications.addInfo info, detail: detail, dismissable: true, icon: 'check'

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
