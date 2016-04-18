request = require 'superagent'
authUtil = require './auth-util'
{Emitter} = require 'atom'
Pusher = require 'pusher-js'
_ = require 'lodash'
config = require '../../config'
# READY:60 The client public_key, secret and pusherKey should be configurable
PRODUCT_ID_NOT_VALID_ERR = new Error "Product ID not valid"
baseUrl = config.baseUrl # READY:50 This should be set to localhost if process.env.IMDONE_ENV = /dev/i
baseAPIUrl = "#{baseUrl}/api/1.0"
accountUrl = "#{baseAPIUrl}/account"
signUpUrl = "#{baseUrl}/signup"
pusherAuthUrl = "#{baseUrl}/pusher/auth"

credKey = 'imdone-atom.credentials'
Pusher.log = (m) -> console.log(m)

module.exports =
class ImdoneioClient extends Emitter
  @PRODUCT_ID_NOT_VALID_ERR: PRODUCT_ID_NOT_VALID_ERR
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
    # TODO:0 Credentials should be stored in $HOME/.imdone/config.json
    @db().insert
      key: authUtil.toBase64("#{@email}:#{@password}")

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
      return cb(PRODUCT_ID_NOT_VALID_ERR) if res.body && res.body.kind == "ObjectId" && res.body.name == "CastError"
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
      return @createProject repo, cb if err == PRODUCT_ID_NOT_VALID_ERR
      return cb err if err
      cb null, project

  syncTasks: (repo, tasks, product, cb) ->
    # DOING:10 Emit progress through the repo so the right board is updated issue:87
    @getOrCreateProject repo, (err, project) =>
      return cb(err) if err
      db = @taskDb(repo)
      #loop


      cb() if cb

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
