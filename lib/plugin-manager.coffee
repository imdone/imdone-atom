{Emitter} = require 'atom'

module.exports =
  emitter: new Emitter
  plugins: {}

  addPlugin: (plugin) ->
    return unless plugin && plugin.name
    @plugins[plugin.name] = plugin
    @emitter.emit 'plugin.added', plugin
