_ = require 'lodash'
async = require 'async'
helper = require './imdone-helper'
log = require('debug/browser') 'imdone-atom:connector-manager'
Task = require 'imdone-core/lib/task'
{Emitter} = require 'atom'

syncTasks = (client, repo, cm) ->
  (tasks) ->
    cm.emit 'tasks.syncing'
    tasks = [tasks] unless _.isArray tasks
    console.log "sending tasks to imdone-io", tasks
    client.syncTasks repo, tasks, (err, tasks) ->
      return if err # TODO: Do something with this error id:414
      console.log "received tasks from imdone-io", tasks
      async.eachSeries tasks,
        # READY: We have to be able to match on meta.id for updates. id:1967
        # READY: Test this with a new project to make sure we get the ids id:1959
        # READY: We need a way to run tests on imdone-io without destroying the client id:1963
        (task, cb) ->
          taskToModify = _.assign repo.getTask(task.id), task
          return cb "Task not found" unless Task.isTask taskToModify
          repo.modifyTask taskToModify, cb
        (err) ->
          return cm.emit 'sync.error', err if err
          repo.saveModifiedFiles (err, files)->
            # DONE: Refresh the board id:1961
            cm.emit 'tasks.updated' unless err

syncFile = (client, repo, cm) ->
  (file) ->
    cm.emit 'tasks.syncing'
    console.log "sending tasks to imdone-io for: %s", file.path, file.getTasks()
    client.syncTasks repo, file.getTasks(), (err, tasks) ->
      return if err # TODO:120 Do something with this error id:414
      console.log "received tasks from imdone-io for: %s", tasks
      async.eachSeries tasks,
        (task, cb) ->
          taskToModify = _.assign repo.getTask(task.id), task
          return cb "Task not found" unless Task.isTask taskToModify
          repo.modifyTask taskToModify, cb
        (err) ->
          return cm.emit 'sync.error', err if err
          repo.writeFile file, (err, file)->
            cm.emit 'tasks.updated' unless err

module.exports =
class ConnectorManager extends Emitter
  products: null

  constructor: (@repo) ->
    super
    @client = require('./imdoneio-client').instance
    @syncTasks = syncTasks @client, @repo, @
    @syncFile = syncFile @client, @repo, @
    @onTasksMove = () => @syncTasks @repo.getTasks()
    @onFileUpdate = (file) => @syncFile file # READY: We need a syncTasks for file so we only save the file that's been modified id:1970
    @handleEvents()
    @onAuthenticated() if @client.isAuthenticated
    # READY: Check for updates to products/connectors and update @products with changes id:415

  handleEvents: ->
    # DONE: Listen for events on repo and update imdone.io with tasks, but on first run we'll have to queue them up for after auth +story id:416

    @client.on 'product.linked', (product) =>
      @setProduct product, (err, product) =>
        @emit 'product.linked', product unless err

    @client.on 'product.unlinked', (product) =>
      @setProduct product, (err, product) =>
        @emit 'product.unlinked', product unless err

    @client.on 'authenticated', => @onAuthenticated()

  onRepoInit: () ->
    return if @project || @initialized
    @client.getOrCreateProject @repo, (err, project) =>
      # TODO: Do something with this error id:1971
      return if err || @project || @initialized
      @project = project
      @syncTasks @repo.getTasks()
      @addTaskListeners()
      @emit 'project.found', project
      @initialized = true

  onAuthenticated: () ->
    log('authenticated');
    @onRepoInit() if @repo.initialized
    @repo.on 'initialized', => @onRepoInit()

  isAuthenticated: () -> @client.isAuthenticated

  addTaskListeners: ->
    @repo.removeListener 'tasks.moved', @onTasksMove
    @repo.on 'tasks.moved', @onTasksMove

    @repo.removeListener 'file.update', @onFileUpdate
    @repo.on 'file.update', @onFileUpdate

    @repo.removeListener 'file.saved', @onFileUpdate
    @repo.on 'file.saved', @onFileUpdate

  projectId: () -> @client.getProjectId @repo

  getProducts: (cb) ->
    cb = (()->) unless cb
    return cb(null, @products) if @products
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
