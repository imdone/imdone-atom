request = require 'superagent'
authUtil = require './auth-util'
p = 'jU-ALYFSinNahQ8cAmFtRgHdzuhAEj9SqbS3CN5mpTRMte8VaAS7cg=='
s = 'k_JgzTw2XCMhqS7buwaoqCxUKiE='
baseUrl = 'http://localhost:3000' # TODO:10 This should be set to localhost if process.env.IMDONE_ENV = /dev/i
baseAPIUrl = "#{baseUrl}/api/1.0"
signUpUrl = "#{baseUrl}/signup"
credKey = 'imdone-atom.credentials'

module.exports =
class ImdoneioClient
  @baseUrl: baseUrl
  @baseAPIUrl: baseAPIUrl
  @signUpUrl: signUpUrl
  authenticated: false

  constructor: () ->
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

    req.end (err, res) =>
      return cb(err, res) if err || !res.ok
      @authenticated = true
      @saveCredentials()
      cb(null, res)

  isAuthenticated: () -> @authenticated

  saveCredentials: () ->
    # TODO:0 Credentials should be stored in $HOME/.imdone/config.json
    atom.config.set(credKey, authUtil.toBase64("#{@email}:#{@password}"))

  loadCredentials: () ->
    credentials = atom.config.get(credKey)
    return false unless credentials
    parts = authUtil.fromBase64(credentials).split(':')
    @email = parts[0]
    @password = parts[1]

  getProducts: (cb) ->
    # READY:0 Implement getProducts
    req = @setHeaders request.get("#{baseAPIUrl}/products")
    req.end (err, res) =>
      return cb(err, res) if err || !res.ok
      cb(null, res.body)
