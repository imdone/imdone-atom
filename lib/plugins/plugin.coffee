{Emitter} = require 'atom'
gitup = require 'git-up'
config = require '../../config'
_ = require 'lodash'
shell = require 'shell'
$el = require 'laconic'
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
  issuesUrlBase: ->
    projectInfo = @githubProjectInfo()
    return unless projectInfo
    "https://github.com/#{projectInfo.accountName}/#{projectInfo.projectName}/issues"
  addMetaKeyConfig: (cb) ->
    projectInfo = @githubProjectInfo()
    return cb() if @metaKeyConfig() || !@idMetaKey() || !projectInfo
    @repo.config.meta = {} unless @repo.config.meta
    issuesUrl = @issuesUrlBase()
    return cb() unless issuesUrl
    @repo.config.meta[@idMetaKey()] =
      urlTemplate: "#{issuesUrl}/%s"
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
    onClick = (e) =>
      $(e.target).find('.task')
      @task = task
      @imdoneView.showPlugin @
      @imdoneView.selectTask id
      @view.setTask task
      @view.show @view.getIssueIds(task)

    $btn = $el.a href: '#', title: title, class: "#{pluginName}", onclick: onClick,
      $el.span class:"icon icon-#{icon}"
    # $btn.on 'click', (e) =>
    #   $(e.target).find('.task')
    #   @task = task
    #   @imdoneView.showPlugin @
    #   @imdoneView.selectTask id
    #   @view.setTask task
    #   @view.show @view.getIssueIds(task)

  projectButtons: () ->
    {$, $$, $$$} = require 'atom-space-pen-views'
    return unless @repo
    connector = @connector
    title = "#{@connector.config.waffleIoProject} waffles!"
    pluginName = @constructor.pluginName
    icon = @constructor.icon
    issuesUrlBase = @issuesUrlBase()
    return unless issuesUrlBase
    $imdonebtn = $$ ->
      @div class:'imdone-icon imdone-toolbar-button', =>
        @a href: "#", title: "", =>
          @i class:'icon', =>
            @tag 'svg', => @tag 'use', "xlink:href":"#imdone-logo-icon"
          @span class:'tool-text', 'Configure imdone.io integrations'
    $imdonebtn.on 'click', (e) => @openImdoneio()
    $wafflebtn = $$ ->
      @div class:"imdone-icon imdone-toolbar-button", =>
        @a href: "#{}", title: title, class: "#{pluginName}-waffle", =>
          @i class:'icon', =>
            @tag 'svg', class:'waffle-logo', => @tag 'use', "xlink:href":"#waffle-logo-icon"
          @span class:'tool-text waffle-logo', "Open waffle.io board"
    $wafflebtn.on 'click', (e) => @openWaffle()
    $githubbtn = $$ ->
      @div class:"imdone-icon imdone-toolbar-button", =>
        @a href: "", title: "GitHub issues", class: "#{pluginName}", =>
          @i class:"icon icon-octoface toolbar-icon"
          @span class:"tool-text", "Open GitHub issues"
    $githubbtn.on 'click', (e) => @openGithub()
    return [$imdonebtn,$wafflebtn,$githubbtn]


    # openWaffle = @openWaffle
    # $btn = $el.div class:"imdone-icon imdone-toolbar-button",
    #   $el.a href:"#{}", title: title, class: "#{pluginName}-waffle",
    #     $el.i class:'icon',
    #       $el 'svg', class:'waffle-logo',
    #         $el 'use', "xlink:href":"#waffle-logo-icon"
    #     $el.span class:'tool-text waffle-logo', "Open waffle.io board"
    # $btn.onclick = () => @openWaffle()
    $($btn)

  openWaffle: -> shell.openExternal @getWaffleURL()
  openImdoneio: -> shell.openExternal "#{config.baseUrl}/account/projects##{@connector._project}"
  openGithub: -> shell.openExternal @issuesUrlBase()
  getWaffleURL: -> "https://waffle.io/#{@connector.config.waffleIoProject}"
