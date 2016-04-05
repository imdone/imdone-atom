request = require 'superagent'
authUtil = require './auth-util'
{Emitter} = require 'atom'
# TODO: The client public_key and secret should be
p = 'GfBC8vMo5JpLufoQjm4236_1mVTocolClAXFsTjcM6ZQ7MAHS8pMEQ=='
s = 'TShVzu_bjjuEUlC1ulTSvb4Qn0Y='
baseUrl = 'http://localhost:3000' # TODO:10 This should be set to localhost if process.env.IMDONE_ENV = /dev/i
baseAPIUrl = "#{baseUrl}/api/1.0"
accountUrl = "#{baseAPIUrl}/account"
signUpUrl = "#{baseUrl}/signup"
credKey = 'imdone-atom.credentials'

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
    req = @setHeaders(request.get(baseAPIUrl))
    self = @

    req.end (err, res) =>
      if err || !res.ok
        @authenticated = false
        delete @password
        delete @email
        return cb(err, res)
      @authenticated = true
      @saveCredentials()
      @getAccount (err, user) =>
        return cb(err) if err
        @user = user
        @emit 'authenticated'
        cb(null, profile)


  isAuthenticated: () -> @authenticated

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
    # READY:0 Implement getProducts
    req = @setHeaders request.get("#{baseAPIUrl}/products")
    req.end (err, res) =>
      return cb(err, res) if err || !res.ok
      cb(null, res.body)

  getAccount: (cb) ->
    # READY:0 Implement getAccount
    req = @setHeaders request.get("#{baseAPIUrl}/account")
    req.end (err, res) =>
      return cb(err, res) if err || !res.ok
      cb(null, res.body)

  @instance: new ImdoneioClient
