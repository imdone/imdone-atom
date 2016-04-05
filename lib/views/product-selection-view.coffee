{$, $$, $$$, SelectListView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
util = require 'util'
Client = require '../services/imdoneio-client'

module.exports =
class ProductSelectionView extends SelectListView
  initialize: ->
    super
    @emitter = new Emitter

  setItems: (products) ->
    super(products)
    @confirmed products[0]

  confirmed: (product) ->
    console.log 'confirmed!'
    @emitter.emit 'product.selected', product

  viewForItem: (product) ->
    # DOING:40 Use style-guide multiple lines with icons
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
