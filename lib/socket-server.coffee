engine = require 'engine.io'
minimatch = require 'minimatch'

# DOING:0 implement socket server to handle opening files in configured client issue:48
module.exports =
  clients: {}
  init: (port) ->
    return @ if @isListening
    @server = engine.listen port
    @server.on 'connection', (socket) =>
      socket.send JSON.stringify(imdone: 'ready')
      socket.on 'message', (msg) =>
        @onMessage socket, msg
    @isListening = true
    @

  onMessage: (socket, json) ->
    try
      msg = JSON.parse json
      if (msg.hello)
        @clients[msg.hello] = socket
      console.log 'message received:', msg
    catch error
      console.log 'Error receiving message:', json

  openFile: (project, path, line, cb) ->
    console.log "Trying to open project:#{project} path:#{path} line:#{line}"
    editor = @getEditor path
    # TODO:10 only send open request to editors who deserve them issue:48
    socket = @getSocket editor
    return cb(false) unless socket
    socket.send JSON.stringify({project, path, line}), () ->
      cb(true)

  getEditor: (path) ->
    openIn = atom.config.get('imdone-atom.openIn')
    for editor, pattern of openIn
      if pattern
        return editor if minimatch(path, pattern, {matchBase: true})
    "atom"

  getSocket: (editor) ->
    @clients[editor]
