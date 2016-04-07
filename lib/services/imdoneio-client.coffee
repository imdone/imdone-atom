request = require 'superagent'
authUtil = require './auth-util'
{Emitter} = require 'atom'
Pusher = require 'pusher-js'
# DOING: The client public_key, secret and pusherKey should be configurable
p = 'GfBC8vMo5JpLufoQjm4236_1mVTocolClAXFsTjcM6ZQ7MAHS8pMEQ=='
s = 'TShVzu_bjjuEUlC1ulTSvb4Qn0Y='
pusherKey = '64354707585286cfe58f'
baseUrl = 'http://localhost:3000' # DOING:10 This should be set to localhost if process.env.IMDONE_ENV = /dev/i
baseAPIUrl = "#{baseUrl}/api/1.0"
accountUrl = "#{baseAPIUrl}/account"
signUpUrl = "#{baseUrl}/signup"
credKey = 'imdone-atom.credentials'
Pusher.log = (m) -> console.log(m)

module.exports =
class ImdoneioClient extends Emitter
  @baseUrl: baseUrl
  @baseAPIUrl: baseAPIUrl
  @signUpUrl: signUpUrl
  authenticated: false

  constructor: () ->
    super
    return unless @loadCredentials()
    @_auth () ->

  setHeaders: (req) ->
    req.set('Date', (new Date()).getTime())
      .set('Accept', 'application/json')
      .set('Authorization', authUtil.getAuth(req, "imdone", @email, @password, s, p));


  authenticate: (@email, password, cb) ->
    @password = authUtil.sha password
    @_auth cb

  _auth: (cb) ->
    @setHeaders(request.get(baseAPIUrl)).end (err, res) =>
      return onAuthFailure cb if err || !res.ok
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

  onAuthFailure: (cb) ->
    @authenticated = false
    delete @password
    delete @email
    cb(err, res)

  isAuthenticated: () -> @authenticated

  setupPusher: () ->
    @pusher = new Pusher pusherKey,
      encrypted: true
      authEndpoint: "#{baseUrl}/pusher/auth"
    # DOING:0 imdoneio pusher channel needs to be configurable
    @pusherChannel = @pusher.subscribe "private-imdoneio-dev-#{@user.id}"
    @pusherChannel.bind 'product.linked', (data) => @emit 'product.linked', data.product
    @pusherChannel.bind 'product.unlinked', (data) => @emit 'product.linked', data.product

  saveCredentials: () ->
    # TODO:0 Credentials should be stored in $HOME/.imdone/config.json
    atom.config.set(credKey, authUtil.toBase64("#{@email}:#{@password}"))

  loadCredentials: () ->
    credentials = atom.config.get(credKey)
    if credentials
      parts = authUtil.fromBase64(credentials).split(':')
      @email = parts[0]
      @password = parts[1]

  getProducts: (cb) ->
    # READY:20 Implement getProducts
    req = @setHeaders request.get("#{baseAPIUrl}/products")
    req.end (err, res) =>
      return cb(err, res) if err || !res.ok
      cb(null, res.body)

  getAccount: (cb) ->
    # READY:10 Implement getAccount
    req = @setHeaders request.get("#{baseAPIUrl}/account")
    req.end (err, res) =>
      return cb(err, res) if err || !res.ok
      cb(null, res.body)

  @instance: new ImdoneioClient
