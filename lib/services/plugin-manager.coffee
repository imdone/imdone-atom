{Emitter} = require 'atom'
_ = require 'lodash'


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

  getAll: -> (val for key, val of @plugins)

  getByProvider: (provider) ->
    _.find(@getAll(), provider: provider) || _.find(@defaultPlugins, provider: provider)

  init: ->
    for plugin in @defaultPlugins
      PluginManager.addPlugin plugin

  removeDefaultPlugins: ->
    for plugin in @defaultPlugins
      PluginManager.removePlugin plugin
