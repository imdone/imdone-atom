request = require 'superagent'
authUtil = require './auth-util'
p = 'pXzjWq8ibolcE5d7BTcdmHecDGeZyE1PKv98aiYZAvo8bfwqtN5ExQ=='
s = 'fIUYLb6fd8Rn__px_ewl6fMB6Cs='
baseUrl = 'http://localhost:3000/api/1.0'

module.exports =
class ImdoneioClient
  setHeaders: (req) ->
    req.set('Date', (new Date()).getTime())
      .set('Accept', 'application/json')
      .set('Authorization', authUtil.getAuth(req, "imdone", @email, @password, s, p));

  authenticate: (@email, password) ->
    @password = authUtil.sha password
    req = @setHeaders(request.get(baseUrl))

    req.end (err, res) =>
      console.log 'err', err
      console.log 'res', res

  isAuthenticated: () ->
    false
