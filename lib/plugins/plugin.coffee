{Emitter} = require 'atom'
gitup = require 'git-up'
_ = require 'lodash'
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
    @view = new @constructor.PluginView({@repo, @imdoneView, @connector})
    @imdoneView.on 'board.update', =>
      return unless @view && @view.is ':visible'
      @imdoneView.selectTask @task.id
    @addMetaKeyConfig =>
      @ready = true
      @emit 'ready'

  setConnector: (@connector) -> @view.setConnector @connector

  githubProjectInfo: ->
    gitUrl = _.get @connector, 'config.repoURL'
    return unless gitUrl
    info = gitup gitUrl
    pathInfo = info.pathname.split '/'
    if pathInfo.length > 2
      len = pathInfo.length
      projectName = pathInfo[len-1]
      dotPos = projectName.indexOf '.'
      info.projectName = projectName.substring 0, dotPos if dotPos > 0
      info.accountName = pathInfo[len-2]
    info

  # Interface ---------------------------------------------------------------------------------------------------------
  isReady: -> @ready
  getView: -> @view
  idMetaKey: -> @connector.config.idMetaKey
  metaKeyConfig: -> @repo.config.meta && @repo.config.meta[@idMetaKey()]
  addMetaKeyConfig: (cb) ->
    return cb() if @metaKeyConfig() || !@idMetaKey()
    projectInfo = @githubProjectInfo()
    @repo.config.meta = {} unless @repo.config.meta
    @repo.config.meta[@idMetaKey()] =
      urlTemplate: "https://github.com/#{projectInfo.accountName}/#{projectInfo.projectName}/issues/%s"
      titleTemplate: "View github issue %s"
      icon: "icon-octoface"
    @repo.saveConfig cb

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
