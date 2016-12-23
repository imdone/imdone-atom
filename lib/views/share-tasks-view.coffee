{$, $$, $$$, View, TextEditorView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
_ = require 'lodash'
util = require 'util'
debug = require 'debug'
log = debug 'imdone-atom:share-tasks-view'
Client = require '../services/imdoneio-client'
ProductSelectionView = require './product-selection-view'
ProductDetailView = require './product-detail-view'
ProjectSettingsView = require './project-settings-view'

module.exports =
class ShareTasksView extends View
  @content: (params) ->
    @div class: "share-tasks-container config-container", =>
      @div outlet: 'spinner', class: 'spinner', style: 'display:none;', =>
        @span class:'loading loading-spinner-small inline-block'
      @subview 'projectSettings', new ProjectSettingsView params
      @div outlet: 'productPanel', class: 'block imdone-product-pane row config-container', style:'display:none;', =>
        @div class: 'product-select-wrapper', =>
          @subview 'productSelect', new ProductSelectionView params
        @div class:'product-detail-wrapper native-key-bindings', =>
          @subview 'productDetail', new ProductDetailView params

  initialize: ({@imdoneRepo, @path, @uri}) ->
    @client = Client.instance
    @show()

  show: () ->
    super
    @onAuthenticated() if @client.isAuthenticated()

  onAuthenticated: () ->  @showProductPanel @imdoneRepo.project if @imdoneRepo.project

  handleEvents: (@emitter) ->
    if @initialized || !@emitter then return else @initialized = true
    @productSelect.handleEvents @emitter
    @productDetail.handleEvents @emitter
    @projectSettings.handleEvents @emitter

    self = @
    @emitter.on 'project.found', (project) => @showProductPanel project

    @emitter.on 'authenticated', => @onAuthenticated()

    @emitter.on 'project.removed', => @productPanel.hide()

  showProductPanel: (@project)->
    @imdoneRepo.getProducts (err, products) =>
      return if err
      @productSelect.setItems products
      @productSelect.show()
      @productPanel.show()
