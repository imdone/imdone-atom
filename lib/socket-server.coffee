engine = require 'engine.io'

# DOING:0 implement socket server to handle opening files in configured client issue:48
module.exports =
  init: (port) ->
    return @ if @isListening
    @server = engine.listen port
    @server.on 'connection', (socket) =>
      msg =
        imdone: 'ready'
      socket.send msg
      socket.on 'message', @onMessage
    @isListening = true
    @

  onMessage: (msg) ->
    console.log 'message received:', msg

  openFile: (project, path) ->
    # TODO:10 only send open request to editors who deserve them issue:48
