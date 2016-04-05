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
      # DOING:30 This has to be configurable for dev and prod
      @a href:product.login, "login" unless product.enabled
      @a href:product.logout, "logout" if product.enabled
