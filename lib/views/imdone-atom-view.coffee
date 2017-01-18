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
_ = null
config = require '../services/imdone-config'
envConfig = require '../../config'

# ICEBOX: Add keen stats for features id:62
module.exports =
class ImdoneAtomView extends ScrollView

  class PluginViewInterface extends Emitter
    constructor: (@imdoneView)->
      super()
    emitter: -> @ # CHANGED: deprecated id:63
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

  constructor: ({@imdoneRepo, @path, @uri}) ->
    super
    util = require 'util'
    Sortable = require 'sortablejs'
    pluginManager = require '../services/plugin-manager'
    fileService = require '../services/file-service'
    @client = require('../services/imdoneio-client').instance
    log = require '../services/log'
    _ = require 'lodash'
    require('./jq-utils')($)

    @title = "#{path.basename(@path)} Tasks"
    @plugins = {}

    @handleEvents()

    @imdoneRepo.fileStats (err, files) =>
      @numFiles = files.length
      @messages.append "<p>Found #{files.length} files in #{path.basename(@path)}</p>"

      if @numFiles > config.getSettings().maxFilesPrompt
        @ignorePrompt.show()
      else
        @messages.append "<p>Looking for TODO's with the following tokens:</p> <p>#{@imdoneRepo.config.code.include_lists.join('<br/>')}</p>"
        @initImdone()

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
        @h1 "Scanning files in #{path.basename(params.path)}."
        @p "Get ready for awesome!!!"
        @div outlet: 'messages', class: 'imdone-messages'

        @div outlet: 'ignorePrompt', class: 'ignore-prompt', style: 'display: none;', =>
          @h2 class:'text-warning', "Help!  Don't make me crash!"
          @p "Too many files make me bloated.  Ignoring files and directories in .imdoneignore can make me feel better."
          @div class: 'block', =>
            @button click: 'openIgnore', class:'inline-block-tight btn btn-primary', "Edit .imdoneignore"
            @button click: 'initImdone', class:'inline-block-tight btn btn-warning', "Who cares, keep going"
        @div outlet: 'progressContainer', style: 'display:none;', =>
          @progress class:'inline-block', outlet: 'progress', max:100, value:1
      @div outlet: 'error', class: 'imdone-error'
      @div outlet: 'mask', class: 'mask', =>
        @div class: 'spinner-mask'
        @div class: 'spinner-container', =>
          @div class: 'spinner', =>
            @p outlet: 'spinnerMessage'
            @p =>
              @span class:'loading loading-spinner-small inline-block'
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

  getURI: -> @uri

  addRepoListeners: ->
    return if @listenersInitialized
    repo = @imdoneRepo
    emitter = @emitter
    handlers = {}
    handle = (event) ->
      (data) -> emitter.emit event, data
    events = ['list.modified', 'project.not-found', 'project.removed', 'project.found', 'product.linked',
      'product.unlinked', 'tasks.updated', 'tasks.syncing', 'sync.error', 'initialized', 'file.update', 'tasks.moved',
      'config.update', 'config.loaded', 'error', 'file.read', 'sync.percent', 'connector.enabled', 'authenticated', 'unauthenticated',
      'authentication-failed', 'unavailable']

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

    @emitter.on 'authentication-failed', ({status, retries}) =>
      @hideMask() if status == "unavailable" && retries
      #console.log "auth-failed" if status == "failed"

    @emitter.on 'unavailable', =>
      @hideMask()
      atom.notifications.addInfo "#{envConfig.name} is unavailable", detail: "Click login to retry", dismissable: true, icon: 'alert'


    @emitter.on 'tasks.syncing', => @showMask "Syncing with #{envConfig.name}..."

    @emitter.on 'sync.error', => @hideMask()

    @emitter.on 'tasks.updated', =>
      @onRepoUpdate()

    @emitter.on 'initialized', =>
      @addPlugin(Plugin) for Plugin in pluginManager.getAll()
      @onRepoUpdate()

    @emitter.on 'list.modified', =>
      #console.log 'list.modified'
      @onRepoUpdate()

    @emitter.on 'file.update', (file) =>
      #console.log 'file.update: %s', file && file.getPath()
      @onRepoUpdate() if file.getPath()

    @emitter.on 'tasks.moved', (tasks) =>
      #console.log 'tasks.moved', tasks
      @onRepoUpdate()

    @emitter.on 'config.update', =>
      #console.log 'config.update'
      repo.refresh()

    @emitter.on 'error', (mdMsg) => atom.notifications.addWarning "OOPS!", description: mdMsg, dismissable: true, icon: 'alert'

    @emitter.on 'task.modified', (task) =>
      #console.log "Task modified.  Syncing with imdone.io"
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

      numFiles = _.keys(paths).length
      if numFiles < 5 || window.confirm "imdone is about to open #{numFiles} files.  Continue?"
        for fpath, line of paths
          #console.log fpath, line
          @openPath fpath, line

    @emitter.on 'tasks.delete', =>
      visibleTasks = @imdoneRepo.visibleTasks()
      return unless visibleTasks
      return unless window.confirm "imdone is about to delete #{visibleTasks.length} tasks.  Continue?"
      @showMask "deleting #{visibleTasks.length} tasks"
      @imdoneRepo.deleteVisibleTasks (err) ->
        @hideMask()

    @emitter.on 'readme.open', =>
      file = _.get @imdoneRepo.getDefaultFile(), 'path'
      unless file
        @emitter.emit 'error', 'Sorry no readme :('
        return
      else
        @openPath @imdoneRepo.getFullPath(file)

    @emitter.on 'repo.change', => @showMask "Loading TODOs..."

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
    @emitter.on 'product.unlinked', (product) => @removePluginByProvider product.name
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

  addPluginProjectButtons: -> @menuView.addPluginProjectButtons @plugins

  addPluginView: (plugin) ->
    return unless plugin.getView
    @bottomView.addPlugin plugin

  initPluginView: (plugin) ->
    @addPluginButtons()
    @addPluginView plugin

  addPlugin: (Plugin) ->
    return unless Plugin
    @imdoneRepo.getProduct Plugin.provider, (err, product) =>
      return if err || (product && !product.isEnabled())
      connector = product && product.connector
      if @plugins[Plugin.pluginName]
        @addPluginButtons()
      else
        plugin = new Plugin @imdoneRepo, @viewInterface, connector
        @plugins[Plugin.pluginName] = plugin
        @imdoneRepo.addPlugin plugin
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
    @imdoneRepo.removePlugin plugin
    @bottomView.removePlugin plugin if plugin && plugin.getView
    delete @plugins[Plugin.pluginName]
    @addPluginButtons()

  removePluginByProvider: (provider) ->
    @removePlugin pluginManager.getByProvider(provider)

  hasPlugins: ->
    Object.keys(@plugins).length > 0

  setFilter: (text) ->
    @menuView.setFilter text
    @menuView.openMenu()
    @boardWrapper.addClass 'shift'

  getFilter: -> @menuView.getFilter()

  filter: (text) ->
    text = @getFilter() unless text
    @lastFilter = text
    if text == ''
      @board.find('.task').show()
    else
      @board.find('.task').hide()
      @filterByPath text
      @filterByContent text
    @emitter.emit 'board.update'

  filterByPath: (text) -> @board.find(util.format('.task:attrContainsRegex(data-path,%s)', text)).each -> $(this).show().attr('id')

  filterByContent: (text) -> @board.find(util.format('.task-full-text:containsRegex("%s")', text)).each -> $(this).closest('.task').show().attr('id')

  visibleTasks: (listName) ->
    return [] unless @imdoneRepo
    @imdoneRepo.visibleTasks listName

  initImdone: () ->
    if @imdoneRepo.initialized
      @onRepoUpdate()
      @menuView.updateMenu()
      @imdoneRepo.initProducts()
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
    # BACKLOG: This should be queued so two updates don't colide id:73
    @showMask 'Updating board'
    @updateBoard()
    @boardWrapper.css 'bottom', 0
    @bottomView.attr 'style', ''
    @loading.hide()
    @mainContainer.show()
    @hideMask()

  showMask: (msg)->
    @spinnerMessage.html msg if msg
    @mask.show()

  hideMask: -> @mask.hide() if @mask

  genFilterLink: (opts) ->
    $$$ ->
      @a href:"#", title: "just show me tasks with #{opts.linkText}", class: "filter-link", "data-filter": opts.linkPrefix.replace( "+", "\\+" )+opts.linkText, =>
        @span class: opts.linkClass, ( if opts.displayPrefix then opts.linkPrefix else "" ) + opts.linkText

  # BACKLOG: Split this apart into it's own class to simplify. Call it BoardView +refactor id:74
  updateBoard: ->
    @destroySortables()
    @board.empty().hide()
    repo = @imdoneRepo
    repo.$board = @board
    lists = repo.getVisibleLists()
    width = 378*lists.length + "px"
    @board.css('width', width)


    # BACKLOG: We can display data from imdone.io in a card summary/details id:76
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
          # BACKLOG: Maybe show assigned avatar on task +feature gh:165 id:77
          @div class: 'imdone-task-plugins'
          @div class: 'task-full-text hidden', task.getText()
          @div class: 'task-text', =>
            @raw html

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
    @hideMask() # TODO: hide mask on event from connectorManager who will retry after emitting id:82
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
        @showMask "Moving Tasks"
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
