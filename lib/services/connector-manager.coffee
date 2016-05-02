_ = require 'lodash'
log = require('debug') 'connector-manager'

module.exports =
class ConnectorManager
  @instance = new ConnectorManager

  init: (repo) ->
    @repo = repo unless @repo
    @initialized = true if @repo

  client: ->
    require('./imdoneio-client').instance

  getConnectors: (cb) ->
    return cb('not initialized') unless @initialized
    @client().getProducts (err, products) =>
      log 'products:', products
      return cb err if err
      # READY:10 Add connector data from .imdone/config.json
      connectors = _.get @repo.getConfig(), 'connectors', []
      return cb null, products unless connectors.length > 0
      products.forEach (product) =>
        connector = _.find connectors, name: product.name
        return unless connector
        product.connector = connector
      cb null, products
