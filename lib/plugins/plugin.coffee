{Emitter} = require 'atom'
module.exports =
class ConnectorPlugin extends Emitter
  @PluginView: require('./plugin-view')
  @pluginName: "github-connector-plugin"
  @provider: "github"
  @title: "Update linked github issues (imdone.io)"
  @icon: "mark-github"

  ready: false
  constructor: (@repo, @imdoneView, @connector) ->
    # We need some way to get the connector!
    super
    @ready = true
    @view = new @constructor.PluginView({@repo, @imdoneView, @connector})
    @emit 'ready'
    @imdoneView.on 'board.update', =>
      return unless @view && @view.is ':visible'
      @imdoneView.selectTask @task.id

  setConnector: (@connector) -> @view.setConnector @connector

  # Interface ---------------------------------------------------------------------------------------------------------
  isReady: ->
    @ready
  getView: ->
    @view
  taskButton: (id) ->
    {$, $$, $$$} = require 'atom-space-pen-views'
    return unless @repo
    task = @repo.getTask(id)
    title = @constructor.title
    pluginName = @constructor.pluginName
    icon = @constructor.icon
    $btn = $$ ->
      @a href: '#', title: title, class: "#{pluginName}", =>
        @span class:"icon icon-#{icon}"
    $btn.on 'click', (e) =>
      $(e.target).find('.task')
      @task = task
      @imdoneView.showPlugin @
      @imdoneView.selectTask id
      @view.setTask task
      @view.show @view.getIssueIds(task)
