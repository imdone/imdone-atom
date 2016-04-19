request = require 'superagent'
async = require 'async'
authUtil = require './auth-util'
{Emitter} = require 'atom'
Pusher = require 'pusher-js'
_ = require 'lodash'
Task = require 'imdone-core/lib/task'
config = require '../../config'
# READY:60 The client public_key, secret and pusherKey should be configurable
PROJECT_ID_NOT_VALID_ERR = new Error "Project ID not valid"
baseUrl = config.baseUrl # READY:50 This should be set to localhost if process.env.IMDONE_ENV = /dev/i
baseAPIUrl = "#{baseUrl}/api/1.0"
accountUrl = "#{baseAPIUrl}/account"
signUpUrl = "#{baseUrl}/signup"
pusherAuthUrl = "#{baseUrl}/pusher/auth"

credKey = 'imdone-atom.credentials'
Pusher.log = (m) -> console.log(m)

module.exports =
class ImdoneioClient extends Emitter
  @PROJECT_ID_NOT_VALID_ERR: PROJECT_ID_NOT_VALID_ERR
  @baseUrl: baseUrl
  @baseAPIUrl: baseAPIUrl
  @signUpUrl: signUpUrl
  authenticated: false

  constructor: () ->
    super
    @loadCredentials (err) =>
      return if err
      @_auth () ->

  setHeaders: (req) ->
    req.set('Date', (new Date()).getTime())
      .set('Accept', 'application/json')
      .set('Authorization', authUtil.getAuth(req, "imdone", @email, @password, config.imdoneKeyB, config.imdoneKeyA));

  _auth: (cb) ->
    @setHeaders(request.get(baseAPIUrl)).end (err, res) =>
      return @onAuthFailure err, res, cb if err || !res.ok
      @onAuthSuccess cb

  onAuthSuccess: (cb) ->
    @getAccount (err, user) =>
      return cb(err) if err
      @saveCredentials()
      @authenticated = true
      @user = user
      @emit 'authenticated'
      @setupPusher()
      cb(null, user)

  onAuthFailure: (err, res, cb) ->
    @authenticated = false
    delete @password
    delete @email
    cb(err, res)

  authenticate: (@email, password, cb) ->
    @password = authUtil.sha password
    @_auth cb

  isAuthenticated: () -> @authenticated

  setupPusher: () ->
    @pusher = new Pusher config.pusherKey,
      encrypted: true
      authEndpoint: pusherAuthUrl
    # READY:20 imdoneio pusher channel needs to be configurable
    @pusherChannel = @pusher.subscribe "#{config.pusherChannelPrefix}-#{@user.id}"
    @pusherChannel.bind 'product.linked', (data) => @emit 'product.linked', data.product
    @pusherChannel.bind 'product.unlinked', (data) => @emit 'product.linked', data.product

  saveCredentials: () ->
    @db().findOne {}, (err, doc) =>
      key = authUtil.toBase64("#{@email}:#{@password}")
      @db().update {_id: doc._id}, {$set: { key: key }}, {upsert: true}, () ->

  loadCredentials: (cb) ->
    @db().find {}, (err, docs) =>
      return cb err if err || docs.length < 1
      parts = authUtil.fromBase64(docs[0].key).split(':')
      @email = parts[0]
      @password = parts[1]
      cb null


  getProducts: (cb) ->
    # READY:100 Implement getProducts
    req = @setHeaders request.get("#{baseAPIUrl}/products")
    req.end (err, res) =>
      return cb(err, res) if err || !res.ok
      cb(null, res.body)

  getAccount: (cb) ->
    # READY:80 Implement getAccount
    req = @setHeaders request.get("#{baseAPIUrl}/account")
    req.end (err, res) =>
      return cb(err, res) if err || !res.ok
      cb(null, res.body)

  getProject: (projectId, cb) ->
    # READY:90 Implement getProject
    req = @setHeaders request.get("#{baseAPIUrl}/projects/#{projectId}")
    req.end (err, res) =>
      return cb(PROJECT_ID_NOT_VALID_ERR) if res.body && res.body.kind == "ObjectId" && res.body.name == "CastError"
      return cb err if err
      cb null, res.body

  getTasks: (projectId, taskIds, cb) ->
    # READY:90 Implement getProject
    return cb null, [] unless taskIds && taskIds.length > 0
    req = @setHeaders request.get("#{baseAPIUrl}/projects/#{projectId}/tasks/#{taskIds.join(',')}")
    req.end (err, res) =>
      return cb(PROJECT_ID_NOT_VALID_ERR) if res.body && res.body.kind == "ObjectId" && res.body.name == "CastError"
      return cb err if err
      cb null, res.body


  createProject: (repo, cb) ->
    # READY:40 Implement createProject
    req = @setHeaders request.post("#{baseAPIUrl}/projects")
    req.send(
      name: repo.getDisplayName()
      localConfig: repo.config.toJSON()
    ).end (err, res) =>
      return cb(err, res) if err || !res.ok
      project = res.body
      _.set repo, 'config.sync.id', project.id
      _.set repo, 'config.sync.name', project.name
      repo.saveConfig()
      cb(null, project)


  getOrCreateProject: (repo, cb) ->
    # READY:30 Implement getOrCreateProject
    projectId = _.get repo, 'config.sync.id'
    return @createProject repo, cb unless projectId
    @getProject projectId, (err, project) =>
      _.set repo, 'config.sync.name', project.name
      repo.saveConfig()
      return @createProject repo, cb if err == PROJECT_ID_NOT_VALID_ERR
      return cb err if err
      cb null, project

  createTasks: (repo, project, tasks, product, cb) ->
    # DONE:50 Implement createTasks
    req = @setHeaders request.post("#{baseAPIUrl}/projects/#{project.id}/tasks")
    updateRepo = (task, cb) =>
      # DOING:20 modifyTask should update text with metadta that doesn't exists
      repo.modifyTask new Task(task.localTask, true), true, cb
    req.send(tasks).end (err, res) =>
      return cb(err, res) if err || !res.ok
      tasks = res.body
      @tasksDb(repo).insert tasks, (err, docs) ->
        async.each docs, updateRepo, cb

  updateTasks: (repo, project, docs, tasks, product, cb) ->
    # DOING:50 Implement updateTasks (does a compare)
    ids = docs.map (obj) -> obj.id
    @getTasks project.id, ids, (err, tasks) =>
      # DOING:0 Compare remote tasks with local tasks for update
      debugger;

  syncTasks: (repo, tasks, product, cb) ->
    cb = if cb then cb else () ->
    # DOING:30 Emit progress through the repo so the right board is updated issue:87
    @getOrCreateProject repo, (err, project) =>
      return cb(err) if err
      @tasksDb(repo).find {}, (err, docs) =>
        return cb err if err
        return @createTasks(repo, project, tasks, product, cb) unless docs && docs.length > 0
        @updateTasks repo, project, docs, tasks, product, cb

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
    #READY:10 return the project specific task DB
    @db 'tasks',repo.getPath().replace(/\//g, '_')

  @instance: new ImdoneioClient
