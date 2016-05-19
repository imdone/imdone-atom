{Emitter} = require 'atom'

# #DONE:120 Write docs for creating plugins issue:42
module.exports = PluginManager =
  emitter: new Emitter
  defaultPlugins: require '../plugins'
  plugins: {}

  addPlugin: (Plugin) ->
    return unless Plugin && Plugin.pluginName
    @plugins[Plugin.pluginName] = Plugin
    @emitter.emit 'plugin.added', Plugin

  removePlugin: (Plugin) ->
    return unless Plugin && Plugin.pluginName && @plugins[Plugin.pluginName]
    @removeByName Plugin.pluginName

  removeByName: (pluginName) ->
    Plugin = @plugins[pluginName]
    delete @plugins[pluginName]
    @emitter.emit 'plugin.removed', Plugin

  getAll: ->
    (val for key, val of @plugins)

  init: ->
    for plugin in @defaultPlugins
      PluginManager.addPlugin plugin

  destroy: ->
    for plugin in @defaultPlugins
      PluginManager.removePlugin plugin
