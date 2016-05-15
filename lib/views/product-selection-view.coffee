{$, $$, $$$, SelectListView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
util = require 'util'

module.exports =
class ProductSelectionView extends SelectListView
  handleEvents: (@emitter) ->
    if @initialized || !@emitter then return else @initialized = true

  setItems: (products) ->
    super(products)
    @selectProduct @getSelectedItem()

  updateItem: (item) ->
    for product, i in @items
      if product.name == item.name
        @items[i] = item
    selectedItem = @getSelectedItem()
    itemSelector = "li[data-name=#{selectedItem.name}]"
    @populateList()
    @selectItemView(@list.find itemSelector)
    @confirmSelection()

  selectProduct: (product) -> @confirmed product

  getProduct: (name) ->
    _ = require 'lodash'
    _.find @items, name: name

  confirmed: (product) ->
    @emitter.emit 'product.selected', product

  viewForItem: (product) ->
    icon = 'icon-sign-in'
    text = 'text-info'
    if product.isEnabled()
      icon = 'icon-cloud-upload'
      text = 'text-success'
    else if product.isLinked()
      icon = 'icon-log-out'
      text = 'text-warning'

    $$ ->
      @li class:"integration-product", 'data-name': product.name, =>
        @div class:"pull-right icon #{icon} #{text}"
        @span class:'product-name', product.name

  getFilterKey: -> 'name'

  cancel: ->
    console.log("cancelled")
