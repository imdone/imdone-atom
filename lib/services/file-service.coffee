engine    = null
eioClient = null
minimatch = null
log       = null


# DONE:100 implement socket server to handle opening files in configured client issue:48 id:578
module.exports =
  clients: {}
  init: (port) ->
    return @ unless @getConfig().openIn.enable
    return @ if @isListening
    engine    = require 'engine.io'
    eioClient = require 'engine.io-client'
    minimatch = require 'minimatch'
    log       = require './log'
    # DONE:50 Check if something else is listening on port issue:51 id:579
    http = require('http').createServer()
    http.on 'error', (err) =>
      if (err.code == 'EADDRINUSE')
        console.log 'port in use'
        @tryProxy port
      log err
    http.listen port, =>
      @server = engine.attach(http);
      @server.on 'connection', (socket) =>
        socket.send JSON.stringify(imdone: 'ready')
        socket.on 'message', (msg) =>
          @onMessage socket, msg
        socket.on 'close', () =>
          editor = (key for key, value of @clients when value == socket)
          delete @clients[editor] if editor
      @isListening = true
      @proxy = undefined
    @

  tryProxy: (port) ->
    # DONE:30 First check if it's imdone listening on the port issue:52 id:580
    # DONE:40 if imdone is listening we should connect as a client and use the server as a proxy issue:52 id:581
    # BACKLOG:160 if imdone is not listening we should ask for another port issue:52 id:582
    log 'Trying proxy'
    socket = eioClient('ws://localhost:' + port)
    socket.on 'open', =>
      socket.send JSON.stringify(hello: 'imdone')
    socket.on 'message', (json) =>
      msg = JSON.parse json
      log 'Proxy success'
      @proxy = socket if msg.imdone
    socket.on 'close', =>
      log 'Proxy server closed connection.  Trying to start server'
      @init port

  onMessage: (socket, json) ->
    try
      msg = JSON.parse json
      if (msg.hello)
        @clients[msg.hello] = socket
      if (msg.isProxied)
        @openFile msg.project, msg.path, msg.line, () ->
      log 'message received:', msg
    catch error
      console.log 'Error receiving message:', json

  openFile: (project, path, line, cb) ->
    return cb() unless @getConfig().openIn.enable
    editor = @getEditor path
    # DONE:90 only send open request to editors who deserve them issue:48 id:583
    socket = @getSocket editor
    return cb() unless socket
    isProxied = if @proxy then true else false
    socket.send JSON.stringify({project, path, line, isProxied}), () ->
      cb(true)

  getEditor: (path) ->
    openIn = atom.config.get('imdone-atom.openIn')
    for editor, pattern of openIn
      if pattern
        return editor if minimatch(path, pattern, {matchBase: true})
    "atom"

  getSocket: (editor) ->
    return @proxy if @proxy && editor != 'atom'
    socket = @clients[editor]
    return null unless socket && @server.clients[socket.id] == socket
    socket

  getConfig: () ->
    atom.config.get('imdone-atom')
