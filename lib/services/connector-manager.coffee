_ = require 'lodash'
helper = require './imdone-helper'
log = require('debug/browser') 'imdone-atom:connector-manager'

module.exports =
class ConnectorManager
  products: null
  constructor: (@repo) ->
    @client = require('./imdoneio-client').instance
    # TODO: Check for updates to products/connectors and update @products with changes

  projectId: () -> @client.getProjectId @repo
  getProducts: (cb) ->
    cb = (()->) unless cb
    return cb(null, @products) if @products
    @client.getProducts @projectId(), (err, products) =>
      return cb(err) if err
      for product in products
        product.connector.defaultSearch = product.defaultSearch if product.connector
        _.mixin product,
          isLinked: () -> this.linked
          isEnabled: () -> this.linked && this.connector && this.connector.enabled
      @products = products
      cb null, products

  getProduct: (provider, cb) ->
    @getProducts (err, products) ->
      cb err, _.find products, name: provider

  saveConnector: (connector, cb) ->
    cb = (()->) unless cb
    return @createConnector connector, cb unless connector.id
    @updateConnector connector, cb

  createConnector: (connector, cb) -> @client.createConnector @repo, connector, cb

  updateConnector: (connector, cb) -> @client.updateConnector @repo, connector, cb

  enableConnector: (connector, cb) -> @client.enableConnector @repo, connector, cb

  disableConnector: (connector, cb) -> @client.disableConnector @repo, connector, cb

  getGitOrigin: () ->
    repo = helper.repoForPath @repo.getPath()
    return null unless repo
    repo.getOriginURL()
