{$, $$, $$$, SelectListView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
util = require 'util'

module.exports =
class ProductSelectionView extends SelectListView
  initialize: ->
    super
    @emitter = new Emitter

  setItems: (products) ->
    super(products)
    @selectProduct @getSelectedItem()

  updateItem: (item) ->
    selectedItem = @getSelectedItem()
    for product, i in @items
      if product.name == item.name
        @items[i] = item
      @selectProduct @items[i] if selectedItem.name == product.name
    console.log @items
    @populateList()

  selectProduct: (product) ->
    @confirmed product

  confirmed: (product) ->
    console.log 'product selected'
    @emitter.emit 'product.selected', product

  viewForItem: (product) ->
    icon   = if product.enabled then 'icon-cloud-upload' else 'icon-sign-in'
    text   = if product.enabled then 'text-success' else 'text-info'

    $$ ->
      @li class:"integration-product", =>
        @div class:"pull-right icon #{icon} #{text}"
        @div =>
          @h4 product.name

  getFilterKey: -> 'name'

  cancel: ->
    console.log("cancelled")
