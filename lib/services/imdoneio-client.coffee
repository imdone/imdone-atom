request = require 'superagent'
authUtil = require './auth-util'
p = 'pXzjWq8ibolcE5d7BTcdmHecDGeZyE1PKv98aiYZAvo8bfwqtN5ExQ=='
s = 'fIUYLb6fd8Rn__px_ewl6fMB6Cs='
baseUrl = 'http://localhost:3000' # TODO:0 This should be set to localhost if process.env.IMDONE_ENV = /dev/i
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
      return cb(err, res) if !res.ok
      @authenticated = true
      @saveCredentials()
      cb(null, res)

  isAuthenticated: () -> @authenticated

  saveCredentials: () ->
    atom.config.set(credKey, authUtil.toBase64("#{@email}:#{@password}"))

  loadCredentials: () ->
    credentials = atom.config.get(credKey)
    console.log "credentials:#{credentials}"
    return false unless credentials
    parts = authUtil.fromBase64(credentials).split(':')
    @email = parts[0]
    @password = parts[1]
