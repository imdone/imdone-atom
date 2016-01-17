{$, $$, $$$, ScrollView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
MenuView = require './menu-view'
BottomView = require './bottom-view'
imdoneHelper = require './imdone-helper'
path = require 'path'
util = require 'util'
Sortable = require 'sortablejs'
pluginManager = require './plugin-manager'
fileService = require './file-service'
log = require './log'
require('./jq-utils')($)

# DOING:10 Add keen stats for features
module.exports =
class ImdoneAtomView extends ScrollView
  atom.deserializers.add(this)

  class PluginViewInterface extends Emitter
    constructor: (@imdoneView)->
      super()
    emitter: -> @ # CHANGED: deprecated
    selectTask: (id) ->
      @imdoneView.selectTask id
    showPlugin: (plugin) ->
      return unless plugin.getView
      @imdoneView.bottomView.showPlugin plugin

  @deserialize: ({data}) ->
    imdoneRepo = imdoneHelper.newImdoneRepo(data.path, data.uri)
    new ImdoneAtomView(imdoneRepo: imdoneRepo, path: data.path, uri: data.uri)

  serialize: -> { deserializer: 'ImdoneAtomView', data: {path: @path, uri: @uri} }

  @content: (params) ->
    @div tabindex: -1, class: 'imdone-atom pane-item', =>
      @div outlet: 'loading', class: 'imdone-loading', =>
        @h1 "Loading #{path.basename(params.path)} Tasks."
        @p "It's gonna be legen... wait for it."
        @ul outlet: 'messages', class: 'imdone-messages'
        # #DONE:290 Update progress bar on repo load
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
            @div outlet: 'board', class: 'imdone-board'
            # @div outlet: 'spinner', =>
            #   @span class: 'loading loading-spinner-large inline-block'
        @div class:'imdone-config-wrapper', =>
          @subview 'bottomView', new BottomView(params)

  getTitle: ->
    @title

  getIconName: ->
    "checklist"

  getURI: ->
    @uri

  initialize: ->
    super

  constructor: ({@imdoneRepo, @path, @uri}) ->
    super
    @title = "#{path.basename(@path)} Tasks"
    @plugins = {}
    @filteredTasks = []

    @handleEvents()
    @imdoneRepo.fileStats (err, files) =>
      @numFiles = files.length
      @messages.append($("<li>Found #{files.length} files in #{@getTitle()}</li>"))
      # #DONE:160 If over 2000 files, ask user to add excludes in `.imdoneignore` +feature
      if @numFiles > atom.config.get('imdone-atom.maxFilesPrompt')
        @ignorePrompt.show()
      else @initImdone()

  handleEvents: ->
    repo = @imdoneRepo
    @emitter = @viewInterface = new PluginViewInterface @

    @imdoneRepo.on 'initialized', =>
      @onRepoUpdate()
      @addPlugin(Plugin) for Plugin in pluginManager.getAll()
    @imdoneRepo.on 'list.modified', =>
      console.log 'list.modified'
      @onRepoUpdate()
    @imdoneRepo.on 'file.update', (file) =>
      console.log 'file.update: %s', file.getPath()
      @onRepoUpdate()
    @imdoneRepo.on 'tasks.move', =>
      console.log 'tasks.move'
      @onRepoUpdate()
      @imdoneRepo.resume()

    @imdoneRepo.on 'config.update', =>
      console.log 'config.update'
      repo.refresh()
    @imdoneRepo.on 'error', (err) => console.log('error:', err)

    @menuView.emitter.on 'menu.toggle', =>
      @boardWrapper.toggleClass 'shift'

    @menuView.emitter.on 'filter', (text) =>
      @filter text

    @menuView.emitter.on 'filter.clear', =>
      @board.find('.task').show()

    @menuView.emitter.on 'filter.open', =>
      paths = {}
      for task in @filteredTasks
        file = @imdoneRepo.getFileForTask(task)
        fullPath = @imdoneRepo.getFullPath file
        paths[fullPath] = task.line
      for fpath, line of paths
        console.log fpath, line
        @openPath fpath, line

    @menuView.emitter.on 'list.new', => @bottomView.showNewList()

    @menuView.emitter.on 'repo.change', => @showMask()

    @bottomView.emitter.on 'config.close', =>
      @appContainer.removeClass 'shift'
      @appContainer.css 'bottom', ''
      @clearSelection()

    @bottomView.emitter.on 'config.open', =>
      @appContainer.addClass 'shift'

    @bottomView.emitter.on 'resize.change', (height) =>
      @appContainer.css('bottom', height + 'px')

    @on 'click', '.source-link',  (e) =>
      link = e.target
      @openPath link.dataset.uri, link.dataset.line
      # DONE:40 Use setting to determine if we should show a task notification
      if atom.config.get('imdone-atom.showNotifications')
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
        repo.on 'initialized', => @addPlugin(Plugin)

    pluginManager.emitter.on 'plugin.removed', (Plugin) =>
      plugin = @plugins[Plugin.pluginName]
      @bottomView.removePlugin plugin if plugin.getView
      delete @plugins[Plugin.pluginName]
      @addPluginTaskButtons()

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

  addPluginView: (plugin) ->
    return unless plugin.getView
    @bottomView.addPlugin plugin

  initPluginView: (plugin) ->
    @addPluginTaskButtons()
    @addPluginView plugin

  addPlugin: (Plugin) ->
    if @plugins[Plugin.pluginName]
      @addPluginTaskButtons()
    else
      plugin = new Plugin @imdoneRepo, @viewInterface
      @plugins[Plugin.pluginName] = plugin
      if plugin instanceof Emitter
        if plugin.isReady()
          @initPluginView plugin
        else
          plugin.on 'ready', => @initPluginView plugin
      else
        @initPluginView plugin

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
    @filteredTasks = []
    if text == ''
      @board.find('.task').show()
    else
      @board.find('.task').hide()
      addTask = (id) =>
        @filteredTasks.push @imdoneRepo.getTask(id)
      @board.find(util.format('.task:regex(data-path,%s)', text)).each ->
        id = $(this).show().attr('id')
        addTask id
      @board.find(util.format('.task-full-text:containsRegex("%s")', text)).each ->
        id = $(this).closest('.task').show().attr('id')
        addTask id
    @menuView.emitter.emit 'filter.tasks', @filteredTasks

  initImdone: () ->
    if @numFiles > 1000
      @ignorePrompt.hide()
      @progressContainer.show()
      @imdoneRepo.on 'file.read', (data) =>
        complete = Math.ceil (data.completed/@numFiles)*100
        @progress.attr 'value', complete
    @imdoneRepo.init()

  openIgnore: () ->
    ignorePath = path.join(@imdoneRepo.path, '.imdoneignore')
    item = @
    atom.workspace.open(ignorePath, split: 'left').then =>
      item.destroy()

  onRepoUpdate: ->
    # DOING:0 This should be queued so two updates don't colide
    @showMask()
    @updateBoard()
    @appContainer.css 'bottom', 0
    @bottomView.attr 'style', ''
    @loading.hide()
    @mainContainer.show()

  showMask: ->
    @mask.show()

  genFilterLink: (opts) ->
    $$$ ->
      @a href:"#", title: "just show me tasks with #{opts.linkText}", class: "filter-link", "data-filter": opts.linkPrefix.replace( "+", "\\+" )+opts.linkText, =>
        @span class: opts.linkClass, ( if opts.displayPrefix then opts.linkPrefix else "" ) + opts.linkText

  updateBoard: ->
    @destroySortables()
    @board.empty().hide()
    repo = @imdoneRepo
    lists = repo.getVisibleLists()
    width = 378*lists.length + "px"
    @board.css('width', width)
    # #DONE:230 Add task drag and drop support

    getTask = (task) =>
      contexts = task.getContext()
      tags = task.getTags()
      dateDue = task.getDateDue()
      dateCreated = task.getDateCreated()
      dateCompleted = task.getDateCompleted()
      opts = $.extend {}, {stripMeta: true, stripDates: true, sanitize: true}, repo.getConfig().marked
      html = task.getHtml(opts)

      if contexts && atom.config.get('imdone-atom.showTagsInline')
        for context, i in contexts
          do (context, i) =>
            html = html.replace( "@#{context}", @genFilterLink linkPrefix: "@", linkText: context, linkClass: "task-context", displayPrefix: true )

      if tags && atom.config.get('imdone-atom.showTagsInline')
        for tag, i in tags
          do (tag, i) =>
            html = html.replace( "+#{tag}", @genFilterLink linkPrefix: "+", linkText: tag, linkClass: "task-tags", displayPrefix: true  )

      self = @;

      $$$ ->
        @li class: 'task well native-key-bindings', id: "#{task.id}", tabindex: -1, "data-path": task.source.path, "data-line": task.line, =>
          # @div class:'task-order', title: 'move task', =>
          #   @span class: 'highlight', task.order
          @div class: 'imdone-task-plugins'
          @div class: 'task-full-text hidden', task.getText()
          @div class: 'task-text', =>
            @raw html
          # #DONE:270 Add todo.txt stuff like chrome app!
          if contexts && ! atom.config.get('imdone-atom.showTagsInline')
            @div =>
              for context, i in contexts
                do (context, i) =>
                  @raw self.genFilterLink linkPrefix: "@", linkText: context, linkClass: "task-context"
                  @span ", " if (i < contexts.length-1)
          if tags && ! atom.config.get('imdone-atom.showTagsInline')
            @div =>
              for tag, i in tags
                do (tag, i) =>
                  @raw self.genFilterLink linkPrefix: "+", linkText: tag, linkClass: "task-tags"
                  @span ", " if (i < tags.length-1)
          @div class: 'task-meta', =>
            @table =>
              # DONE:90 x 2015-11-20 2015-11-20 Fix todo.txt date display @piascikj due:2015-11-20 issue:45
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
                    # #DONE:210 Implement #filter/*filterRegex* links
                    @a href:"#", title: "filter by completed on #{dateCompleted}", class: "filter-link", "data-filter": "x #{dateCompleted}", =>
                      @span class:"icon icon-light-bulb"
              for data in task.getMetaDataWithLinks(repo.getConfig())
                do (data) =>
                  @tr =>
                    @td data.key
                    @td data.value
                    @td =>
                      @a href:"#", title: "just show me tasks with #{data.key}:#{data.value}", class: "filter-link", "data-filter": "#{data.key}:#{data.value}", =>
                        @span class:"icon icon-light-bulb"
                      if data.link
                          @a href: data.link.url, title: data.link.title, =>
                            @span class:"icon icon-link-external"
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
              # #DONE:240 Add delete list icon if length is 0
              if (tasks.length < 1)
                @a href: '#', title: "delete #{list.name}", class: 'delete-list', "data-list": list.name, =>
                  @span class:'icon icon-trashcan'
          @ol class: 'tasks', "data-list":"#{list.name}", =>
            @raw getTask(task) for task in tasks

    elements = (-> getList list for list in lists)

    @board.append elements
    @addPluginTaskButtons()
    @filter()
    @board.show()
    @mask.hide()
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
        @imdoneRepo.pause()
        @imdoneRepo.moveTasks [task], list, pos

    @tasksSortables = tasksSortables = []
    @find('.tasks').each ->
      tasksSortables.push(Sortable.create $(this).get(0), opts)

  destroy: ->
    @emitter.emit 'did-destroy', @
    @imdoneRepo.destroy()
    @emitter.dispose()
    @remove()

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback

  openPath: (filePath, line) ->
    return unless filePath
    # DONE:120 send the project path issue:48
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
