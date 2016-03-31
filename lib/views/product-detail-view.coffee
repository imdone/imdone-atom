{$, $$, $$$, View} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
util = require 'util'
Client = require '../services/imdoneio-client'

module.exports =
class ProductDetailView extends View
  @content: (params) ->
    @div class: 'product-detail-view-content'

  setProduct: (@product)->
    @draw()

  draw: ->
    return unless @product && @product.name
    @html @getDetail(@product)

  getDetail: (product) ->
    $$ ->
      @h1 "#{product.name}"
