{Emitter} = require 'atom'

module.exports =
class WebhookConnectorPlugin extends Emitter
  @PluginView: undefined
  @pluginName: "webhook-plugin"
  @provider: "webhook"
  @title: "Deliver tasks to a webhook"
  @icon: "server"

  constructor: (@repo, @imdoneView, @connector) -> @emit 'ready'

  setConnector: (@connector) -> 

  # Interface ---------------------------------------------------------------------------------------------------------
  isReady: -> true
