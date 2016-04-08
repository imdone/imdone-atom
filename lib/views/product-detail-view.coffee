{$, $$, $$$, View} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
util = require 'util'

module.exports =
class ProductDetailView extends View
  @content: (params) ->
    @div outlet:'$detail', class: 'product-detail-view-content'

  setProduct: (@product)->
    @draw()

  draw: ->
    return unless @product && @product.name
    @html @getDetail(@product)

  getDetail: (product) ->
    $$ ->
      @h1 "#{product.name}"
      # TODO: This will have to be upadted on an event sent with pusher
      @div class:'block', =>
        if product.enabled
          @a href:product.logout, class:'btn icon icon-log-out inline-block-tight', 'logout'
          @button class:'btn icon icon icon-repo-sync inline-block-tight', 'sync board'
        else
          @a href:product.login, class:'btn icon icon-log-in inline-block-tight', 'login'
