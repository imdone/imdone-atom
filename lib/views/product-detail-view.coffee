{$, $$, $$$, View} = require 'atom-space-pen-views'
_ = require 'lodash'
util = require 'util'

module.exports =
class ProductDetailView extends View
  initialize: ({@imdoneRepo, @path, @uri}) ->

  updateConnectorForEdit: (product) ->
    _.set product, 'connector', {} unless product.connector
    return unless product.name == 'github' && !_.get(product, 'connector.config.repoURL')
    _.set product, 'connector.config.repoURL', @imdoneRepo.getGitOrigin() || ''

  handleEvents: (@emitter)->
    return if @initialized || !@emitter
    @initialized = true
    # @on 'click', '#create-tasks', =>
    #   @emitter.emit 'tasks.create', @product.name
    @emitter.on 'project.removed', (project) =>
      @$configEditor.empty()
      @configEditor.destroy() if @configEditor
      delete @product

    @emitter.on 'product.selected', (product) =>
      return unless product
      @updateConnectorForEdit product
      @setProduct product

    @emitter.on 'product.linked', (product) =>
      return unless product
      @updateConnectorForEdit product
      @setProduct product

    @emitter.on 'product.unlinked', (product) =>
      return unless product
      # READY: Connector plugin should be removed id:92
      @updateConnectorForEdit product
      @setProduct product

    @emitter.on 'connector.changed', (product) =>
      return unless product
      @updateConnectorForEdit product
      @setProduct product


  @content: (params) ->
    require 'json-editor'
    @div class: 'product-detail-view-content config-container', =>
      @div class: 'json-editor-container', =>
        @div outlet: '$configEditor', class: 'json-editor native-key-bindings'
      @div outlet: '$welcome', class: 'block text-center', style: 'display:none;', =>
        @h1 "No TODOBOTS yet?  Turn on GitHub now."
        @h2 "Let's make programming fun again!"

  setProduct: (@product)->
    return unless @product && @product.name
    @$configEditor.empty()
    return unless @product.linked
    @createEditor()

  createEditor: ->
    options =
      schema: @product.schemas.config # TODO: Rule schemas to be set by GET /projects/ :projectId/products +rules-workflow id:93
      startval: @product.connector.config # TODO: Rule values to be set by GET /projects/ :projectId/products +rules id:94
      theme: 'bootstrap3'
      required_by_default: true
      disable_edit_json: true
      disable_properties: true
      disable_collapse: true
      disable_array_delete_last_row: true
      disable_array_delete_all_rows: true

    # TODO: Add provider configurations before creating editor id:95
    @configEditor.destroy() if @configEditor
    if @product.isEnabled()
      @showConfig()
      @configEditor = new JSONEditor @$configEditor.get(0), options
      @configEditor.on 'change', => @handleChange()
      @$configEditor.find('input').first().focus()
    else
      @hideConfig()

  hideConfig: ->
    @$configEditor.hide()
    @$welcome.show()

  showConfig: ->
    @$configEditor.show()
    @$welcome.hide()

  handleChange: ->
    editorVal = @configEditor.getValue()
    currentVal =  _.get @product, 'connector.config'
    return unless @product.isEnabled()
    return if _.isEqual editorVal, currentVal
    _.set @product, 'connector.config', editorVal
    _.set @product, 'connector.name', @product.name unless _.get @product, "connector.name"
    connector = _.cloneDeep @product.connector
    @imdoneRepo.saveConnector connector, (err, connector) =>
      # TODO: Handle errors by unauthenticating if needed and show login with error id:96
      # DOING: Need a way to handle repos that don't allow issues (Forks, etc).  Maybe two settings. (gitub repo and github issues repo) +enhancement gh:142 id:97
      return if err
      @product.connector = connector
      @setProduct @product
