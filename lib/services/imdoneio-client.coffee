request = require 'superagent'
async = require 'async'
authUtil = require './auth-util'
{Emitter} = require 'atom'
{allowUnsafeEval} = require 'loophole'
Pusher = allowUnsafeEval -> require 'pusher-js'
_ = require 'lodash'
Task = require 'imdone-core/lib/task'
config = require '../../config'
debug = require('debug/browser')
log = debug 'imdone-atom:client'

# READY:150 The client public_key, secret and pusherKey should be configurable
PROJECT_ID_NOT_VALID_ERR = new Error "Project ID not valid"
baseUrl = config.baseUrl # READY:140 This should be set to localhost if process.env.IMDONE_ENV = /dev/i
baseAPIUrl = "#{baseUrl}/api/1.0"
accountUrl = "#{baseAPIUrl}/account"
signUpUrl = "#{baseUrl}/signup"
pusherAuthUrl = "#{baseUrl}/pusher/auth"

credKey = 'imdone-atom.credentials'
Pusher.log = debug 'imdone-atom:pusher'

module.exports =
class ImdoneioClient extends Emitter
  @PROJECT_ID_NOT_VALID_ERR: PROJECT_ID_NOT_VALID_ERR
  @baseUrl: baseUrl
  @baseAPIUrl: baseAPIUrl
  @signUpUrl: signUpUrl
  authenticated: false

  constructor: () ->
    super
    @on 'storage.auth.error', =>
      setTimeout =>
        @authFromStorage()
      , 2000
    @authFromStorage()

  setHeaders: (req) ->
    log 'setHeaders:begin'
    withHeaders = req.set('Date', (new Date()).getTime())
      .set('Accept', 'application/json')
      .set('Authorization', authUtil.getAuth(req, "imdone", @email, @password, config.imdoneKeyB, config.imdoneKeyA));
    log 'setHeaders:end'
    withHeaders

  doGet: (path) ->
    @setHeaders request.get("#{baseAPIUrl}#{path || ''}")

  doPost: (path) ->
    @setHeaders request.post("#{baseAPIUrl}#{path}")

  doPatch: (path) ->
    @setHeaders request.patch("#{baseAPIUrl}#{path}")

  _auth: (cb) ->
    @getAccount (err, user) =>
      return @onAuthFailure err, user, cb if err
      @onAuthSuccess user, cb

  authFromStorage: (cb) ->
    cb = (() ->) unless cb
    @loadCredentials (err) =>
      return cb err if err
      @_auth (err, user) =>
        @emit 'storage.auth.error' if err && err.code == "ECONNREFUSED"
        # TODO:60 if err.status == 404 we should show an error
        cb err, user

  onAuthSuccess: (user, cb) ->
    @authenticated = true
    @user = user
    @emit 'authenticated'
    @saveCredentials (err) =>
      cb(null, user)
      log 'onAuthSuccess'
      @setupPusher()

  onAuthFailure: (err, res, cb) ->
    @authenticated = false
    delete @password
    delete @email
    cb(err, res)

  authenticate: (@email, password, cb) ->
    log 'authenticate:start'
    @password = authUtil.sha password
    @_auth cb

  isAuthenticated: () -> @authenticated

  setupPusher: () ->
    @pusher = new Pusher config.pusherKey,
      encrypted: true
      authEndpoint: pusherAuthUrl
      disableStats: true
    # READY:80 imdoneio pusher channel needs to be configurable
    @pusherChannel = @pusher.subscribe "#{config.pusherChannelPrefix}-#{@user.id}"
    @pusherChannel.bind 'product.linked', (data) => @emit 'product.linked', data.product
    @pusherChannel.bind 'product.unlinked', (data) => @emit 'product.linked', data.product
    log 'setupPusher'

  saveCredentials: (cb) ->
    @db().remove {}, {}, (err) =>
      log 'saveCredentials'
      return cb err if (err)
      key = authUtil.toBase64("#{@email}:#{@password}")
      @db().insert key: key, cb

  loadCredentials: (cb) ->
    @db().findOne {}, (err, doc) =>
      return cb err if err || !doc
      parts = authUtil.fromBase64(doc.key).split(':')
      @email = parts[0]
      @password = parts[1]
      cb null


  getProducts: (projectId, cb) ->
    # READY:190 Implement getProducts
    @doGet("/projects/#{projectId}/products").end (err, res) =>
      return cb(err, res) if err || !res.ok
      cb(null, res.body)

  getAccount: (cb) ->
    log 'getAccount:start'
    @doGet("/account").end (err, res) =>
      log 'getAccount:end'
      return cb(err, res) if err || !res.ok
      cb(null, res.body)

  getProject: (projectId, cb) ->
    # READY:170 Implement getProject
    @doGet("/projects/#{projectId}").end (err, res) =>
      return cb(PROJECT_ID_NOT_VALID_ERR) if res.body && res.body.kind == "ObjectId" && res.body.name == "CastError"
      return cb err if err
      cb null, res.body

  getTasks: (projectId, taskIds, cb) ->
    # READY:180 Implement getProject
    return cb null, [] unless taskIds && taskIds.length > 0
    @doGet("/projects/#{projectId}/tasks/#{taskIds.join(',')}").end (err, res) =>
      return cb(PROJECT_ID_NOT_VALID_ERR) if res.body && res.body.kind == "ObjectId" && res.body.name == "CastError"
      return cb err if err
      cb null, res.body

  createConnector: (repo, connector, cb) ->
    projectId = @getProjectId repo
    return cb "project must have a sync.id to connect" unless projectId
    # READY:100 Implement createProject
    @doPost("/projects/#{projectId}/connectors").send(connector).end (err, res) =>
      return cb(err, res) if err || !res.ok
      cb(null, res.body)

  updateConnector: (repo, connector, cb) ->
    projectId = @getProjectId repo
    return cb "project must have a sync.id to connect" unless projectId
    # READY:110 Implement createProject
    @doPatch("/projects/#{projectId}/connectors/#{connector.id}").send(connector).end (err, res) =>
      return cb(err, res) if err || !res.ok
      cb(null, res.body)

  enableConnector: (repo, connector, cb) ->
    @_connectorAction repo, connector, "enable", cb

  disableConnector: (repo, connector, cb) ->
    @_connectorAction repo, connector, "disable", cb

  _connectorAction: (repo, connector, action, cb) ->
    projectId = @getProjectId repo
    return cb "project must have a sync.id to connect" unless projectId
    # READY:110 Implement createProject
    @doPost("/projects/#{projectId}/connectors/#{connector.id}/#{action}").send(connector).end (err, res) =>
      return cb(err, res) if err || !res.ok
      cb(null, res.body)

  createProject: (repo, cb) ->
    # READY:120 Implement createProject
    @doPost("/projects").send(
      name: repo.getDisplayName()
      localConfig: repo.config.toJSON()
    ).end (err, res) =>
      return cb(err, res) if err || !res.ok
      project = res.body
      # TODO:40 This should be in connectorManager
      @setProjectId repo, project.id
      @setProjectName repo, project.name
      repo.saveConfig()
      cb(null, project)


  getOrCreateProject: (repo, cb) ->
    # READY:90 Implement getOrCreateProject
    # TODO:70 move this to connectorManager
    projectId = @getProjectId repo
    return @createProject repo, cb unless projectId
    @getProject projectId, (err, project) =>
      return cb err if err
      # TODO:50 This should be in connectorManager
      @setProjectName repo, project.name
      repo.saveConfig()
      return @createProject repo, cb if err == PROJECT_ID_NOT_VALID_ERR
      return cb err if err
      cb null, project

  getProjectId: (repo) -> _.get repo, 'config.sync.id'
  setProjectId: (repo, id) -> _.set repo, 'config.sync.id', id
  getProjectName: (repo) -> _.get repo, 'config.sync.name'
  setProjectName: (repo, name) -> _.set repo, 'config.sync.name', name

  createTasks: (repo, project, tasks, product, cb) ->
    # READY:130 Implement createTasks
    # READY:50 modifyTask should update text with metadata that doesn't exists
    updateRepo = (task, cb) => repo.modifyTask new Task(task.localTask, true), cb
    @doPost("/projects/#{project.id}/tasks").send(tasks).end (err, res) =>
      return cb(err, res) if err || !res.ok
      tasks = res.body
      @tasksDb(repo).insert tasks, (err, docs) =>
        async.eachSeries docs, updateRepo, (err) =>
          repo.saveModifiedFiles cb

  updateTasks: (repo, project, product, cb) ->
    # BACKLOG:10 Should we really do this for all local tasks or do we ask api for task id's, dates and text checksum?  We can compare them before running rules.
    # Next step would be to sync down or up any changes if rules apply
    @tasksDb(repo).find {}, (err, localTasks) =>
      localIds = localTasks.map (task) -> task.id
      @getTasks project.id, localIds, (err, cloudTasks) =>
        console.log 'cloudTasks', cloudTasks
        console.log 'localTasks', localTasks
        cloudTasks.forEach (cloudTask) =>
          localTask = _.find(localTasks, {id: cloudTask.id})
          # BACKLOG:20 Use rules to determine if and how cloud tasks and local tasks should be synced
        cb()

  syncTasks: (repo, tasks, product, cb) ->
    cb = if cb then cb else () ->
    # BACKLOG:30 Emit progress through the repo so the right board is updated
    # READY:20 getOrCreateProject should happen when we get products, if we know a product is linked
    @getOrCreateProject repo, (err, project) =>
      return cb(err) if err
      tasksToCreate = tasks.filter (task) -> !_.get(task, "meta.id")
      return @createTasks repo, project, tasksToCreate, product, cb if tasksToCreate
      cb()
      # @updateTasks repo, project, product, (err) =>
      #   return @createTasks repo, project, tasksToCreate, product, cb if tasksToCreate
      #   cb err

  # collection can be an array of strings or string
  db: (collection) ->
    path = require 'path'
    collection = path.join.apply @, arguments if arguments.length > 1
    collection = "config" unless collection
    @datastore = {} unless @datastore
    return @datastore[collection] unless !@datastore[collection]
    DataStore = require('nedb')
    @datastore[collection] = new DataStore
      filename: path.join atom.getConfigDirPath(), 'storage', 'imdone-atom', collection
      autoload: true
    @datastore[collection]

  tasksDb: (repo) ->
    #READY:70 return the project specific task DB
    @db 'tasks',repo.getPath().replace(/\//g, '_')

  @instance: new ImdoneioClient
