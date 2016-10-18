{$, $$, $$$, ScrollView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
fs = require 'fs'
MenuView = null
BottomView = null
path = null
util = null
Sortable = null
pluginManager = null
fileService = null
log = null
config = require '../services/imdone-config'
envConfig = require '../../config'

# INBOX: Add keen stats for features
module.exports =
class ImdoneAtomView extends ScrollView

  class PluginViewInterface extends Emitter
    constructor: (@imdoneView)->
      super()
    emitter: -> @ # CHANGED: deprecated
    selectTask: (id) ->
      @imdoneView.selectTask id
    showPlugin: (plugin) ->
      return unless plugin.getView
      @imdoneView.bottomView.showPlugin plugin

  initialize: ->
    super
    @zoom config.getSettings().zoomLevel
    # imdone icon stuff
    svgPath = path.join config.getPackagePath(), 'images', 'icons.svg'
    fs.readFile svgPath, (err, data) =>
      return if err
      @$svg.html data.toString()

  constructor: ({@imdoneRepo, @path, @uri, @connectorManager}) ->
    super
    util = require 'util'
    Sortable = require 'sortablejs'
    pluginManager = require '../services/plugin-manager'
    fileService = require '../services/file-service'
    @client = require('../services/imdoneio-client').instance
    log = require '../services/log'
    require('./jq-utils')($)

    @title = "#{path.basename(@path)} Tasks"
    @plugins = {}

    @handleEvents()

    @imdoneRepo.fileStats (err, files) =>
      @numFiles = files.length
      @messages.append($("<li>Found #{files.length} files in #{@getTitle()}</li>"))
      # #DONE: If over 2000 files, ask user to add excludes in `.imdoneignore` +feature
      if @numFiles > config.getSettings().maxFilesPrompt
        @ignorePrompt.show()
      else @initImdone()

  serialize: ->
    deserializer: 'ImdoneAtomView'
    path: @path
    uri: @uri

  zoom: (dir) ->
    zoomable = @find '.zoomable'
    return zoomable.css 'zoom', dir if typeof dir is 'number'
    zoomVal = new Number(zoomable.css 'zoom')
    zoomVal = if dir == 'in' then zoomVal+.05 else zoomVal-.05
    zoomable.css 'zoom', zoomVal

  @content: (params) ->
    MenuView = require './menu-view'
    BottomView = require './bottom-view'
    path = require 'path'
    @div tabindex: -1, class: 'imdone-atom pane-item', =>
      @div outlet: '$svg'
      @div outlet: 'loading', class: 'imdone-loading', =>
        @h1 "Loading #{path.basename(params.path)} Tasks."
        @p "It's gonna be legen... wait for it."
        @ul outlet: 'messages', class: 'imdone-messages'
        # #DONE: Update progress bar on repo load
        @div outlet: 'ignorePrompt', class: 'ignore-prompt', style: 'display: none;', =>
          @h2 class:'text-warning', "Help!  Don't make me crash!"
          @p "Too many files make me bloated.  Ignoring files and directories in .imdoneignore can make me feel better."
          @div class: 'block', =>
            @button click: 'openIgnore', class:'inline-block-tight btn btn-primary', "Edit .imdoneignore"
            @button click: 'initImdone', class:'inline-block-tight btn btn-warning', "Who cares, keep going"
        @div outlet: 'progressContainer', style: 'display: none;', =>
          @progress class:'inline-block', outlet: 'progress', max:100, value:1
      @div outlet: 'error', class: 'imdone-error'
      @div outlet: 'mask', class: 'mask', =>
        @div class: 'spinner-mask'
        @div class: 'spinner-container' #, =>
          # @div class: 'spinner', =>
            # @span class:'loading loading-spinner-large inline-block'
      @div outlet:'mainContainer', class:'imdone-main-container', =>
        @div outlet: 'appContainer', class:'imdone-app-container', =>
          @subview 'menuView', new MenuView(params)
          @div outlet: 'boardWrapper', class: 'imdone-board-wrapper native-key-bindings', =>
            # @div outlet: 'messages', "HAHAH"
            @div outlet: 'board', class: 'imdone-board zoomable'
          @div outlet: 'configWrapper', class:'imdone-config-wrapper', =>
            @subview 'bottomView', new BottomView(params)

  getTitle: -> @title

  getIconName: -> "checklist"

  getURI: ->
    @uri

  addRepoListeners: ->
    return if @listenersInitialized
    repo = @imdoneRepo
    emitter = @emitter
    handlers = {}
    handle = (event) ->
      (data) -> emitter.emit event, data
    events = ['list.modified', 'project.not-found', 'project.removed', 'project.found', 'tasks.updated', 'initialized',
      'file.update', 'tasks.moved', 'config.update', 'error', 'file.read', 'sync.percent', 'connector.enabled']
    for event in events
      handler = handlers[event] = handle event
      repo.on event, handler
    @removeAllRepoListeners = () ->
      repo.removeListener(event, handlers[event]) for event in events
    @listenersInitialized = true

  handleEvents: ->
    repo = @imdoneRepo
    @emitter = @viewInterface = new PluginViewInterface @
    @addRepoListeners()
    @menuView.handleEvents @emitter
    @bottomView.handleEvents @emitter

    @client.on 'authentication-failed', ({status, retries}) =>
      @hideMask() if status == "unavailable" && retries
      console.log "auth-failed" if status == "failed"

    @client.on 'unavailable', =>
      @hideMask()
      atom.notifications.addInfo "#{envConfig.name} is unavailable", detail: "Click login to retry", dismissable: true, icon: 'alert'

    @connectorManager.on 'tasks.syncing', => @showMask() # READY: mask isn't always hiding correctly gh:105

    @connectorManager.on 'sync.error', => @hideMask()

    @emitter.on 'tasks.updated', => # READY: If syncing don't fire onRepoUpdate.  Wait until done syncing. gh:105
      @onRepoUpdate()

    @emitter.on 'initialized', =>
      @addPlugin(Plugin) for Plugin in pluginManager.getAll()
      @onRepoUpdate()

    @emitter.on 'list.modified', =>
      console.log 'list.modified'
      @onRepoUpdate()

    @emitter.on 'file.update', (file) =>
      console.log 'file.update: %s', file && file.getPath()
      @onRepoUpdate() if file.getPath()

    @emitter.on 'tasks.moved', (tasks) =>
      console.log 'tasks.moved', tasks
      @onRepoUpdate()

    @emitter.on 'config.update', =>
      console.log 'config.update'
      repo.refresh()

    @emitter.on 'error', (err) => console.log('error:', err)

    @emitter.on 'task.modified', (task) =>
      console.log "Task modified.  Syncing with imdone.io"
      @imdoneRepo.syncTasks [task], (err) => @onRepoUpdate()

    @emitter.on 'menu.toggle', =>
      @boardWrapper.toggleClass 'shift'

    @emitter.on 'filter', (text) =>
      @filter text

    @emitter.on 'filter.clear', =>
      @board.find('.task').show()

    @emitter.on 'visible.open', =>
      paths = {}
      for task in @visibleTasks()
        file = @imdoneRepo.getFileForTask(task)
        fullPath = @imdoneRepo.getFullPath file
        paths[fullPath] = task.line
      for fpath, line of paths
        console.log fpath, line
        @openPath fpath, line

    @emitter.on 'repo.change', => @showMask()

    @emitter.on 'config.close', =>
      @boardWrapper.removeClass 'shift-bottom'
      @boardWrapper.css 'bottom', ''
      @clearSelection()

    @emitter.on 'config.open', =>
      @boardWrapper.addClass 'shift-bottom'

    @emitter.on 'resize.change', (height) =>
      @boardWrapper.css('bottom', height + 'px')

    @emitter.on 'zoom', (dir) => @zoom dir

    @on 'click', '.source-link',  (e) =>
      link = e.target
      @openPath link.dataset.uri, link.dataset.line
      # DONE: Use setting to determine if we should show a task notification
      if config.getSettings().showNotifications
        taskId = $(link).closest('.task').attr 'id'
        task = @imdoneRepo.getTask taskId
        atom.notifications.addInfo task.list, detail: task.text, dismissable: true, icon: 'check'

    @on 'click', '.list-name', (e) =>
      name = e.target.dataset.list
      @bottomView.editListName(name)

    @on 'click', '.delete-list', (e) =>
      e.stopPropagation()
      e.preventDefault()
      target = e.target
      name = target.dataset.list || target.parentElement.dataset.list
      repo.removeList(name)

    @on 'click', '.filter-link', (e) =>
      target = e.target
      filter = target.dataset.filter || target.parentElement.dataset.filter
      @setFilter filter

    @on 'click', '[href^="#filter/"]', (e) =>
      target = e.target
      target = target.closest('a') unless (target.nodeName == 'A')
      e.stopPropagation()
      e.preventDefault()
      filterAry = target.getAttribute('href').split('/');
      filterAry.shift()
      filter = filterAry.join '/' ;
      @setFilter filter

    pluginManager.emitter.on 'plugin.added', (Plugin) =>
      if (repo.getConfig())
        @addPlugin(Plugin)
      else
        @emitter.on 'initialized', => @addPlugin(Plugin)

    pluginManager.emitter.on 'plugin.removed', (Plugin) => @removePlugin Plugin

    @emitter.on 'connector.disabled', (connector) => @removePluginByProvider connector.name
    @emitter.on 'connector.enabled', (connector) => @addPluginByProvider connector.name
    @connectorManager.on 'product.unlinked', (product) => @removePluginByProvider product.name
    @emitter.on 'connector.changed', (product) =>
      @addPluginByProvider product.connector.name
      for name, plugin of @plugins
        plugin.setConnector product.connector if plugin.constructor.provider == product.name

    @emitter.on 'logoff', => pluginManager.removeDefaultPlugins()
    @emitter.on 'project.removed', => pluginManager.removeDefaultPlugins()


  addPluginButtons: ->
    @addPluginTaskButtons()
    @addPluginProjectButtons()

  addPluginTaskButtons: ->
    @board.find('.imdone-task-plugins').empty()
    return unless @hasPlugins()
    plugins = @plugins
    @board.find('.task').each ->
      $task = $(this)
      $taskPlugins = $task.find '.imdone-task-plugins'
      id = $task.attr('id')
      for name, plugin of plugins
        if typeof plugin.taskButton is 'function'
          $button = plugin.taskButton(id)
          if $button
            $button.addClass 'task-plugin-button'
            $taskPlugins.append $button

  addPluginProjectButtons: -> @menuView.addPluginProjectButtons @plugins # TODO: Add the plugin project buttons here

  addPluginView: (plugin) ->
    return unless plugin.getView
    @bottomView.addPlugin plugin

  initPluginView: (plugin) ->
    @addPluginButtons()
    @addPluginView plugin

  addPlugin: (Plugin) ->
    return unless Plugin
    @connectorManager.getProduct Plugin.provider, (err, product) => # READY: Get the connector from the connector manager
      return if err || (product && !product.isEnabled())
      connector = product && product.connector
      if @plugins[Plugin.pluginName]
        @addPluginButtons()
      else
        plugin = new Plugin @imdoneRepo, @viewInterface, connector
        @plugins[Plugin.pluginName] = plugin
        if plugin instanceof Emitter
          if plugin.isReady()
            @initPluginView plugin
          else
            plugin.on 'ready', => @initPluginView plugin
        else
          @initPluginView plugin

  addPluginByProvider: (provider) ->
    @addPlugin pluginManager.getByProvider(provider)

  removePlugin: (Plugin) ->
    return unless Plugin
    plugin = @plugins[Plugin.pluginName]
    @bottomView.removePlugin plugin if plugin && plugin.getView
    delete @plugins[Plugin.pluginName]
    @addPluginButtons()

  removePluginByProvider: (provider) ->
    @removePlugin pluginManager.getByProvider(provider)

  hasPlugins: ->
    Object.keys(@plugins).length > 0

  setFilter: (text) ->
    @menuView.setFilter text
    @menuView.addClass 'open'
    @boardWrapper.addClass 'shift'

  getFilter: ->
    @menuView.getFilter()

  filter: (text) ->
    text = @getFilter() unless text
    @lastFilter = text
    if text == ''
      @board.find('.task').show()
    else
      @board.find('.task').hide()
      @board.find(util.format('.task:regex(data-path,%s)', text)).each ->
        id = $(this).show().attr('id')
      @board.find(util.format('.task-full-text:containsRegex("%s")', text)).each ->
        id = $(this).closest('.task').show().attr('id')

  visibleTasks: ->
    visibleTasks = []
    addTask = (id) =>
      visibleTasks.push @imdoneRepo.getTask(id)
    @board.find('.task').each ->
      return if $(this).is ':hidden'
      addTask $(this).attr('id')

    visibleTasks

  initImdone: () ->
    if @imdoneRepo.initialized
      @onRepoUpdate()
      @menuView.updateMenu()
      @imdoneRepo.initProducts()
      # @connectorManager.getProducts() #TODO we should add plugins by provider from here
      return
    if @numFiles > 1000
      @ignorePrompt.hide()
      @progressContainer.show()
      @emitter.on 'file.read', (data) =>
        complete = Math.ceil (data.completed/@numFiles)*100
        @progress.attr 'value', complete
    @imdoneRepo.init()

  openIgnore: () ->
    ignorePath = path.join(@imdoneRepo.path, '.imdoneignore')
    item = @
    atom.workspace.open(ignorePath, split: 'left').then =>
      item.destroy()

  onRepoUpdate: ->
    # BACKLOG: This should be queued so two updates don't colide
    @showMask()
    @updateBoard()
    @boardWrapper.css 'bottom', 0
    @bottomView.attr 'style', ''
    @loading.hide()
    @mainContainer.show()
    @hideMask()

  showMask: ->
    @menuView.showSpinner()
    @mask.show()

  hideMask: ->
    @menuView.hideSpinner()
    @mask.hide() if @mask

  genFilterLink: (opts) ->
    $$$ ->
      @a href:"#", title: "just show me tasks with #{opts.linkText}", class: "filter-link", "data-filter": opts.linkPrefix.replace( "+", "\\+" )+opts.linkText, =>
        @span class: opts.linkClass, ( if opts.displayPrefix then opts.linkPrefix else "" ) + opts.linkText

  # BACKLOG: Split this apart into it's own class to simplify. Call it BoardView +refactor
  updateBoard: ->
    @destroySortables()
    @board.empty().hide()
    repo = @imdoneRepo
    lists = repo.getVisibleLists()
    width = 378*lists.length + "px"
    @board.css('width', width)
    # #DONE: Add task drag and drop support

    # BACKLOG: We can display data from imdone.io in a card summary/details
    getTask = (task) =>
      contexts = task.getContext()
      tags = task.getTags()
      dateDue = task.getDateDue()
      dateCreated = task.getDateCreated()
      dateCompleted = task.getDateCompleted()
      opts = $.extend {}, {stripMeta: true, stripDates: true, sanitize: true}, repo.getConfig().marked
      html = task.getHtml(opts)
      showTagsInline = config.getSettings().showTagsInline

      if contexts && showTagsInline
        for context, i in contexts
          do (context, i) =>
            html = html.replace( "@#{context}", @genFilterLink linkPrefix: "@", linkText: context, linkClass: "task-context", displayPrefix: true )

      if tags && showTagsInline
        for tag, i in tags
          do (tag, i) =>
            html = html.replace( "+#{tag}", @genFilterLink linkPrefix: "+", linkText: tag, linkClass: "task-tags", displayPrefix: true  )

      self = @;

      $$$ ->
        @li class: 'task well native-key-bindings', id: "#{task.id}", tabindex: -1, "data-path": task.source.path, "data-line": task.line, =>
          # @div class:'task-order', title: 'move task', =>
          #   @span class: 'highlight', task.order
          # BACKLOG: Maybe show assigned avatar on task +feature
          @div class: 'imdone-task-plugins'
          @div class: 'task-full-text hidden', task.getText()
          @div class: 'task-text', =>
            @raw html
          # #DONE: Add todo.txt stuff like chrome app!
          if contexts && !showTagsInline
            @div =>
              for context, i in contexts
                do (context, i) =>
                  @raw self.genFilterLink linkPrefix: "@", linkText: context, linkClass: "task-context"
                  @span ", " if (i < contexts.length-1)
          if tags && !showTagsInline
            @div =>
              for tag, i in tags
                do (tag, i) =>
                  @raw self.genFilterLink linkPrefix: "+", linkText: tag, linkClass: "task-tags"
                  @span ", " if (i < tags.length-1)
          @div class: 'task-meta', =>
            @table =>
              # DONE: x 2015-11-20 2015-11-20 Fix todo.txt date display @piascikj issue:45
              if dateDue
                @tr =>
                  @td "due"
                  @td dateDue
                  @td =>
                    @a href:"#", title: "filter by due:#{dateDue}", class: "filter-link", "data-filter": "due:#{dateDue}", =>
                      @span class:"icon icon-light-bulb"
              if dateCreated
                @tr =>
                  @td "created"
                  @td dateCreated
                  @td =>
                    @a href:"#", title: "filter by created on #{dateCreated}", class: "filter-link", "data-filter": "(x\\s\\d{4}-\\d{2}-\\d{2}\\s)?#{dateCreated}", =>
                      @span class:"icon icon-light-bulb"
              if dateCompleted
                @tr =>
                  @td "completed"
                  @td dateCompleted
                  @td =>
                    # #DONE: Implement #filter/*filterRegex* links
                    @a href:"#", title: "filter by completed on #{dateCompleted}", class: "filter-link", "data-filter": "x #{dateCompleted}", =>
                      @span class:"icon icon-light-bulb"
              for data in task.getMetaDataWithLinks(repo.getConfig())
                do (data) =>
                  @tr =>
                    @td data.key
                    @td data.value
                    @td =>
                      if data.link
                        @a href: data.link.url, title: data.link.title, =>
                          @span class:"icon #{data.link.icon || 'icon-link-external'}"
                      @a href:"#", title: "just show me tasks with #{data.key}:#{data.value}", class: "filter-link", "data-filter": "#{data.key}:#{data.value}", =>
                        @span class:"icon icon-light-bulb"
          @div class: 'task-source', =>
            @a href: '#', class: 'source-link', title: 'take me to the source', 'data-uri': "#{repo.getFullPath(task.source.path)}",
            'data-line': task.line, "#{task.source.path + ':' + task.line}"

    getList = (list) =>
      $$ ->
        tasks = repo.getTasksInList(list.name)
        @div class: 'top list well', =>
          @div class: 'list-name-wrapper well', =>
            @div class: 'list-name', 'data-list': list.name, title: "I don't like this name", =>
              @raw list.name
              # #DONE: Add delete list icon if length is 0
              if (tasks.length < 1)
                @a href: '#', title: "delete #{list.name}", class: 'delete-list', "data-list": list.name, =>
                  @span class:'icon icon-trashcan'
          @ol class: 'tasks', "data-list":"#{list.name}", =>
            @raw getTask(task) for task in tasks

    elements = (-> getList list for list in lists)

    @board.append elements
    @addPluginButtons()
    @filter()
    @board.show()
    @hideMask() # TODO: hide mask on event from connectorManager who will retry after emitting
    @makeTasksSortable()
    @emitter.emit 'board.update'

  destroySortables: ->
    if @tasksSortables
      for sortable in @tasksSortables
        sortable.destroy() if sortable.el

  makeTasksSortable: ->
    opts =
      draggable: '.task'
      group: 'tasks'
      sort: true
      ghostClass: 'imdone-ghost'
      scroll: @boardWrapper[0]
      onEnd: (evt) =>
        id = evt.item.id
        pos = evt.newIndex
        list = evt.item.parentNode.dataset.list
        filePath = @imdoneRepo.getFullPath evt.item.dataset.path
        task = @imdoneRepo.getTask id
        @showMask()
        @imdoneRepo.moveTasks [task], list, pos

    @tasksSortables = tasksSortables = []
    @find('.tasks').each ->
      tasksSortables.push(Sortable.create $(this).get(0), opts)

  destroy: ->
    @removeAllRepoListeners()
    @remove()
    @emitter.emit 'did-destroy', @
    @emitter.dispose()

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback

  openPath: (filePath, line) ->
    return unless filePath
    # DONE: send the project path issue:48
    fileService.openFile @path, filePath, line, (success) =>
      return if success
      atom.workspace.open(filePath, split: 'left').then =>
        @moveCursorTo(line) if line

  moveCursorTo: (lineNumber) ->
    lineNumber = parseInt(lineNumber)

    if textEditor = atom.workspace.getActiveTextEditor()
      position = [lineNumber-1, 0]
      textEditor.setCursorBufferPosition(position, autoscroll: false)
      textEditor.scrollToCursorPosition(center: true)

  selectTask: (id) ->
    @clearSelection()
    @board.find(".task##{id}").addClass 'selected'

  clearSelection: ->
    @board.find('.task').removeClass 'selected'
