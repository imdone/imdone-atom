{$, $$, $$$, View} = require 'atom-space-pen-views'
util = require 'util'
require 'json-editor'

module.exports =
class ProductDetailView extends View
  handleEvents: (@emitter)->
    if @initialized || !@emitter then return else @initialized = true
    @on 'click', '#create-tasks', =>
      @emitter.emit 'tasks.create', @product.name

  @content: (params) ->
    @div class: 'product-detail-view-content config-container vertical-scroll', =>
      @div outlet: '$detail'
      @div outlet: '$configEditor', class: 'json-editor native-key-bindings'

  setProduct: (@product)->
    @draw()

  draw: ->
    return unless @product && @product.name
    @$detail.html @getDetail(@product)
    return unless @product.enabled
    options =
      schema: @product.schemas.config
      theme: 'bootstrap3'
      required_by_default: true
      disable_edit_json: true
      disable_properties: true
      disable_collapse: true
      startval: @product.connector

    @configEditor.destroy() if @configEditor
    @configEditor = new JSONEditor @$configEditor.get(0), options
    @emitChange()
    @configEditor.on 'change', => @emitChange()

  emitChange: ->
    @product.connector = @configEditor.getValue()
    @emitter.emit 'connector.change', @product

  getDetail: (product) ->
    $$ ->
      @h1 "#{product.name}"
      # TODO:30 This will have to be upadted on an event sent with pusher
      @div class:'block', =>
        if product.enabled
          @a href:product.logout, class:'btn icon icon-log-out inline-block-tight', "unlink your #{product.name} account"
          @button id:'create-tasks', class:'btn icon icon icon-cloud-upload inline-block-tight', "create #{product.entity}s on #{product.name}"
        else
          @a href:product.login, class:'btn icon icon-log-in inline-block-tight', "link your #{product.name} account"
