_ = require 'lodash'
async = require 'async'
helper = require './imdone-helper'
log = require('debug/browser') 'imdone-atom:connector-manager'
Task = require 'imdone-core/lib/task'
{Emitter} = require 'atom'

syncTasks = (client, repo, cm) ->
  (tasks) ->
    tasks = [tasks] unless _.isArray tasks
    console.log "sending tasks to imdone-io", tasks
    client.syncTasks repo, tasks, (err, tasks) ->
      return if err # TODO:70 Do something with this error id:414
      console.log "received tasks from imdone-io", tasks
      async.eachSeries tasks,
        # READY:60 We have to be able to match on meta.id for updates. id:1967
        # READY:10 Test this with a new project to make sure we get the ids id:1959 githubClosed:true
        # READY:0 We need a way to run tests on imdone-io without destroying the client id:1963 githubClosed:true
        (task, cb) ->
          taskToModify = _.assign(repo.getTask(task.id), task);
          # READY:30 If there's no match then this won't work.  Make sure this is a Task id:1968 githubClosed:true
          taskToModify = new Task(taskToModify) unless Task.isTask(taskToModify)
          repo.modifyTask(taskToModify, cb)
        (err) ->
          repo.saveModifiedFiles (err, files)->
            # DONE:0 Refresh the board id:1961
            cm.emit 'tasks.updated' unless err

syncFile = (client, repo, cm) ->
  (file) ->
    console.log "sending tasks to imdone-io for: %s", file.path, file.getTasks()
    client.syncTasks repo, file.getTasks(), (err, tasks) ->
      return if err # TODO:70 Do something with this error id:414
      console.log "received tasks from imdone-io for: %s", tasks
      async.eachSeries tasks,
        (task, cb) ->
          taskToModify = _.assign(repo.getTask(task.id), task);
          taskToModify = new Task(taskToModify) unless Task.isTask(taskToModify)
          repo.modifyTask(taskToModify, cb)
        (err) ->
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
    @onFileUpdate = (file) => @syncFile file # READY:20 We need a syncTasks for file so we only save the file that's been modified id:1970 githubClosed:true
    @handleEvents()
    @onAuthenticated() if @client.isAuthenticated
    # READY:80 Check for updates to products/connectors and update @products with changes id:415

  handleEvents: ->
    # DONE:270 Listen for events on repo and update imdone.io with tasks, but on first run we'll have to queue them up for after auth +story id:416

    @client.on 'product.linked', (product) =>
      @setProduct product, (err, product) =>
        @emit 'product.linked', product unless err

    @client.on 'product.unlinked', (product) =>
      @setProduct product, (err, product) =>
        @emit 'product.unlinked', product unless err

    @client.on 'authenticated', => @onAuthenticated()
    # @client.on 'connector.enabled', (connector) => @setConnector connector
    #
    # @client.on 'connector.disabled', (connector) => @setConnector connector
    #
    # @client.on 'connector.changed', (connector) => @setConnector connector
    #
    # @client.on 'connector.created', (connector) => @setConnector connector

  onRepoInit: () ->
    return if @project || @initialized
    @client.getOrCreateProject @repo, (err, project) =>
      return if err
      @project = project
      @syncTasks @repo.getTasks()
      @addTaskListeners()
      @emit 'project.found', project
      @initialized = true

  onAuthenticated: () ->
    log('authenticated');
    @onRepoInit() if @repo.initialized
    @repo.on 'initialized', => @onRepoInit()

  addTaskListeners: ->
    @repo.removeListener 'tasks.moved', @onTasksMove
    @repo.on 'tasks.moved', @onTasksMove

    @repo.removeListener 'file.update', @onFileUpdate
    @repo.on 'file.update', @onFileUpdate

    # @repo.removeListener 'task.found', @syncTasks
    # @repo.on 'task.found', @syncTasks

  projectId: () -> @client.getProjectId @repo

  getProducts: (cb) ->
    cb = (()->) unless cb
    return cb(null, @products) if @products
    @client.getProducts @projectId(), (err, products) =>
      return cb err  if err
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
