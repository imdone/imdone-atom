{$, $$, $$$, View} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
util = require 'util'

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
      # TODO: This will have to be upadted on an event sent with pusher
      @a href:product.login, "login" unless product.enabled
      @a href:product.logout, "logout" if product.enabled
