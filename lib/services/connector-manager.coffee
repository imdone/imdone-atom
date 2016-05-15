_ = require 'lodash'
helper = require './imdone-helper'
log = require('debug/browser') 'imdone-atom:connector-manager'

module.exports =
class ConnectorManager
  constructor: (@repo) ->

  client: ->
    require('./imdoneio-client').instance

  getProducts: (cb) ->
    cb = (()->) unless cb
    projectId = @client().getProjectId(@repo)
    @client().getProducts projectId, (err, products) =>
      return cb(err) if err
      for product in products
        _.mixin product,
          isLinked: () -> this.linked
          isEnabled: () -> this.linked && this.connector && this.connector.enabled
      cb null, products

  saveConnector: (connector, cb) ->
    cb = (()->) unless cb
    return @createConnector connector, cb unless connector.id
    @updateConnector connector, cb

  createConnector: (connector, cb) -> @client().createConnector @repo, connector, cb

  updateConnector: (connector, cb) -> @client().updateConnector @repo, connector, cb

  enableConnector: (connector, cb) -> @client().enableConnector @repo, connector, cb

  disableConnector: (connector, cb) -> @client().disableConnector @repo, connector, cb

  getGitOrigin: () ->
    repo = helper.repoForPath @repo.getPath()
    return null unless repo
    repo.getOriginURL()
