_ = require 'lodash'
async = require 'async'
helper = require './imdone-helper'
log = require('debug/browser') 'imdone-atom:connector-manager'
Task = require 'imdone-core/lib/task'
{Emitter} = require 'atom'

module.exports =
class ConnectorManager extends Emitter
  products: null

  constructor: (@repo) ->
    super
    @client = require('./imdoneio-client').instance
    @handleEvents()
    @onAuthenticated() if @client.isAuthenticated
    # READY:70 Check for updates to products/connectors and update @products with changes id:15

  handleEvents: ->
    # DONE:0 Listen for events on repo and update imdone.io with tasks, but on first run we'll have to queue them up for after auth +story id:16

    @client.on 'product.linked', (product) =>
      @setProduct product, (err, product) =>
        @emit 'product.linked', product unless err

    @client.on 'product.unlinked', (product) =>
      @setProduct product, (err, product) =>
        @emit 'product.unlinked', product unless err

    @client.on 'authenticated', => @onAuthenticated()

  onRepoInit: () ->
    # TODO:60 This should be moved to imdoneio-store id:17
    return if @project || @initialized || @initializing
    return unless @isAuthenticated()
    @initializing = true
    @client.getOrCreateProject @repo, (err, project) =>
      # TODO:80 Do something with this error id:18
      @initializing = false
      return if err || @project || @initialized
      @project = project
      @repo.syncTasks @repo.getTasks(), (err, done) =>
        @emit 'project.found', project
        @initialized = true
        done err

  onAuthenticated: () ->
    log('authenticated');
    @onRepoInit() if @repo.initialized
    @repo.on 'initialized', => @onRepoInit()

  isAuthenticated: () -> @client.isAuthenticated()

  projectId: () -> @client.getProjectId @repo

  updateTaskOrder: (order, cb) ->
    return cb() unless @project
    @project.taskOrder = order
    @client.updateProject @project, (err, project) =>
      return cb(err) if err
      cb null, project.taskOrder

  getProducts: (cb) ->
    cb = (()->) unless cb
    return cb "unauthenticated" unless @isAuthenticated()
    return cb null, @products if @products
    return cb "No project found" unless @projectId()
    @client.getProducts @projectId(), (err, products) =>
      return cb err if err
      @enhanceProduct product for product in products
      @products = products
      cb null, products

  getProduct: (provider, cb) ->
    @getProducts (err, products) ->
      cb err, _.find products, name: provider

  setProduct: (newProduct, cb) ->
    cb = (()->) unless cb
    @getProduct newProduct.name, (err, product) ->
      return cb err  if err
      _.assign product, newProduct
      product.linked = newProduct.linked
      _.set product, 'connector.enabled', _.get(newProduct, 'connector.enabled')
      cb null, product

  setConnector: (connector, cb) ->
    @getProduct connector.name, (err, product) =>
      return cb err  if err
      product.connector = connector
      @enhanceProduct  product
      cb null, connector

  saveConnector: (connector, cb) ->
    cb = (()->) unless cb
    return @createConnector connector, cb unless connector.id
    @updateConnector connector, cb

  createConnector: (connector, cb) ->
    @client.createConnector @repo, connector, cb

  updateConnector: (connector, cb) ->
    @client.updateConnector @repo, connector, (err, connector) =>
      return cb err if err
      @setConnector connector, cb

  enableConnector: (connector, cb) ->
    @client.enableConnector @repo, connector, (err, connector) =>
      return cb err if err
      @setConnector connector, cb

  disableConnector: (connector, cb) ->
    @client.disableConnector @repo, connector, (err, connector) =>
      return cb err if err
      @setConnector connector, cb

  getGitOrigin: () ->
    repo = helper.repoForPath @repo.getPath()
    return null unless repo
    repo.getOriginURL()

  enhanceProduct: (product) ->
    product.connector.defaultSearch = product.defaultSearch if product.connector
    _.mixin product,
      isLinked: () -> this.linked
      isEnabled: () -> this.linked && this.connector && this.connector.enabled
