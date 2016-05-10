{$, $$, $$$, View} = require 'atom-space-pen-views'
util = require 'util'
_ = require 'lodash'
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
    debugger
    return unless @product && @product.name
    @$detail.html @getDetail(@product)
    @$configEditor.empty()
    return unless @product.enabled
    @createEditor()

  createEditor: ->
    options =
      schema: @product.schemas.config
      startval: @product.connector.config
      theme: 'bootstrap3'
      required_by_default: true
      disable_edit_json: true
      disable_properties: true
      disable_collapse: true

    @configEditor.destroy() if @configEditor
    @configEditor = new JSONEditor @$configEditor.get(0), options
    @emitChange()
    @configEditor.on 'change', => @emitChange()

  emitChange: ->
    editorValue = @configEditor.getValue()
    apiValue =  _.get(@product, 'connector.config')
    debugger
    return if _.isEqual editorValue, apiValue
    _.set @product, 'connector.config', editorValue
    _.set @product, 'connector.name', @product.name
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
