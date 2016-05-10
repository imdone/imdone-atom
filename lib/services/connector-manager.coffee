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
    @client().getProducts projectId, cb

  saveConnector: (connector, cb) ->
    # DOING:30 Connector must have a name
    cb = (()->) unless cb
    return @createConnector connector, cb unless connector.id
    @updateConnector connector, cb
    # DOING:50 connectors data should be stored remotely and config.json used as a backup

  createConnector: (connector, cb) ->
    @client().createConnector @repo, connector, (err, doc) =>
      return cb err if err
      cb null, doc

  updateConnector: (connector, cb) ->
    # DOING:40 Update the connector on imdone-io
    @client().updateConnector @repo, connector, (err, doc) =>
      return cb err if err
      cb null, doc

  getGitOrigin: () ->
    repo = helper.repoForPath @repo.getPath()
    return null unless repo
    repo.getOriginURL()
