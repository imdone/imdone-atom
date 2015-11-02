{$, $$, $$$, ScrollView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
MenuView = require './menu-view'
ConfigView = require './config-view'
imdoneHelper = require './imdone-helper'
path = require 'path'
util = require 'util'
Sortable = require 'sortablejs'
pluginManager = require './plugin-manager'
require('./jq-utils')($)

module.exports =
class ImdoneAtomView extends ScrollView
  atom.deserializers.add(this)
  @deserialize: ({data}) ->
    imdoneRepo = imdoneHelper.newImdoneRepo(data.path, data.uri)
    new ImdoneAtomView(imdoneRepo: imdoneRepo, path: data.path, uri: data.uri)

  serialize: -> { deserializer: 'ImdoneAtomView', data: {path: @path, uri: @uri} }

  @content: (params) ->
    @div class: 'imdone-atom pane-item', =>
      @div outlet: 'loading', class: 'imdone-loading', =>
        @h1 "Loading #{path.basename(params.path)} Issues."
        @p "It's gonna be legen... wait for it."
        @ul outlet: 'messages', class: 'imdone-messages'
        # #DONE:170 Update progress bar on repo load
        @div outlet: 'ignorePrompt', class: 'ignore-prompt', style: 'display: none;', =>
          @h2 class:'text-warning', "Help!  Don't make me crash!"
          @p "Too many files make me bloated.  Ignoring files and directories in .imdoneignore can make me feel better."
          @div class: 'block', =>
            @button click: 'openIgnore', class:'inline-block-tight btn btn-primary', "Edit .imdoneignore"
            @button click: 'initImdone', class:'inline-block-tight btn btn-warning', "Who cares, keep going"
        @div outlet: 'progressContainer', style: 'display: none;', =>
          @progress class:'inline-block', outlet: 'progress', max:100, value:1
      @div outlet: 'error', class: 'imdone-error'
      @div outlet:'mainContainer', class:'imdone-main-container', =>
        @div outlet: 'appContainer', class:'imdone-app-container', =>
          @subview 'menuView', new MenuView(params)
          @div outlet: 'boardWrapper', class: 'imdone-board-wrapper', =>
            @div outlet: 'board', class: 'imdone-board'
            # @div outlet: 'spinner', =>
            #   @span class: 'loading loading-spinner-large inline-block'
        @div class:'imdone-config-wrapper', =>
          @subview 'configView', new ConfigView(params)

  getTitle: ->
    "#{path.basename(@path)} Issues"

  getIconName: ->
    "checklist"

  getURI: ->
    @uri

  constructor: ({@imdoneRepo, @path, @uri}) ->
    super
    @plugins = {}
    @emitter = new Emitter
    @handleEvents()
    @imdoneRepo.fileStats (err, files) =>
      @numFiles = files.length
      @messages.append($("<li>Found #{files.length} files in #{@getTitle()}</li>"))
      # #DONE:50 If over 2000 files, ask user to add excludes in `.imdoneignore` +feature
      if @numFiles > atom.config.get('imdone-atom.maxFilesPrompt')
        @ignorePrompt.show()
      else @initImdone()

  handleEvents: ->
    repo = @imdoneRepo

    @imdoneRepo.on 'initialized', =>
      @onRepoUpdate()
      @addPlugin(Plugin) for Plugin in pluginManager.getAll()
    @imdoneRepo.on 'list.modified', =>
      console.log 'list.modified'
      @onRepoUpdate()
    @imdoneRepo.on 'file.update', =>
      console.log 'file.update'
      @onRepoUpdate()
    @imdoneRepo.on 'tasks.move', =>
      console.log 'tasks.move'
      @onRepoUpdate()
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

    @menuView.emitter.on 'list.new', => @configView.showNewList()

    @configView.emitter.on 'config.close', =>
      @appContainer.removeClass 'shift'
      @appContainer.css 'bottom', ''

    @configView.emitter.on 'config.open', =>
      @appContainer.addClass 'shift'

    @configView.emitter.on 'resize.change', (height) =>
      @appContainer.css('bottom', height + 'px')

    @on 'click', '.source-link',  (e) =>
      link = e.target
      @openPath link.dataset.uri, link.dataset.line

    @on 'click', '.list-name', (e) =>
      name = e.target.dataset.list
      @configView.editListName(name)

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
      delete @plugins[Plugin.pluginName]
      @addPluginTaskButtons()

  addPluginTaskButtons: ->
    return unless @hasPlugins()
    plugins = @plugins
    @board.find('.imdone-task-plugins').empty()
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
    @configView.addPlugin plugin

  initPluginView: (plugin) ->
    @addPluginTaskButtons()
    @addPluginView plugin

  addPlugin: (Plugin) ->
    if @plugins[Plugin.pluginName]
      @addPluginTaskButtons()
    else
      plugin = new Plugin @imdoneRepo
      @plugins[Plugin.pluginName] = plugin
      if plugin instanceof Emitter
        if plugin.isReady()
          @initPluginView(plugin)
        else
          plugin.on 'ready', => @initPluginView(plugin)
      else
        @initPluginView(plugin)

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
      @board.find(util.format('.task:regex(data-path,%s)', text)).show()
      @board.find(util.format('.task-full-text:containsRegex("%s")', text)).each( ->
        $(this).closest('.task').show()
      )

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
    atom.workspace.open(ignorePath, split: 'left').done =>
      item.destroy()

  onRepoUpdate: ->
    @updateBoard()
    @appContainer.css 'bottom', 0
    @configView.attr 'style', ''
    @loading.hide()
    @mainContainer.show()

  updateBoard: ->
    @board.empty().hide()
    repo = @imdoneRepo
    lists = repo.getVisibleLists()
    width = 378*lists.length + "px"
    @board.css('width', width)
    # #DONE:110 Add task drag and drop support

    getTask = (task) =>
      contexts = task.getContext()
      tags = task.getTags()
      dateDue = task.getDateDue()
      dateCreated = task.getDateCreated()
      dateCompleted = task.getDateCompleted()
      opts = $.extend {}, {stripMeta: true, stripDates: true, sanitize: true}, repo.getConfig().marked
      html = task.getHtml(opts)
      $$$ ->
        @li class: 'task well', id: "#{task.id}", "data-path": task.source.path, =>
          # @div class:'task-order', title: 'move task', =>
          #   @span class: 'highlight', task.order
          @div class: 'imdone-task-plugins'
          @div class: 'task-full-text hidden', task.getText()
          @div class: 'task-text', =>
            @raw html
          # #DONE:150 Add todo.txt stuff like chrome app!
          if contexts
            @div =>
              for context, i in contexts
                do (context, i) =>
                  @a href:"#", title: "just show me tasks with @#{context}", class: "filter-link", "data-filter": "@#{context}", =>
                    @span class: "task-context", context
                    @span ", " if (i < contexts.length-1)
          if tags
            @div =>
              for tag, i in tags
                do (tag, i) =>
                  @a href:"#", title: "just show me tasks with +#{tag}", class: "filter-link", "data-filter": "\\+#{tag}", =>
                    @span class: "task-tags", tag
                    @span ", " if (i < tags.length-1)
          @div class: 'task-meta', =>
            @table =>
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
                      # #DONE:90 Implement #filter/*filterRegex* links
                      @a href:"#", title: "filter by completed on #{dateCompleted}", class: "filter-link", "data-filter": "x #{dateCompleted}", =>
                        @span class:"icon icon-light-bulb"
          @div class: 'task-source', =>
            @a class: 'source-link', title: 'take me to the source', 'data-uri': "#{repo.getFullPath(task.source.path)}",
            'data-line': task.line, "#{task.source.path + ':' + task.line}"

    getList = (list) =>
      $$ ->
        tasks = repo.getTasksInList(list.name)
        @div class: 'top list well', =>
          @div class: 'list-name-wrapper well', =>
            @div class: 'list-name', 'data-list': list.name, title: "I don't like this name", =>
              @raw list.name
              # #DONE:120 Add delete list icon if length is 0
              if (tasks.length < 1)
                @a href: '#', title: "delete #{list.name}", class: 'delete-list', "data-list": list.name, =>
                  @span class:'icon icon-trashcan'
          @ol class: 'tasks', "data-list":"#{list.name}", =>
            @raw getTask(task) for task in tasks

    elements = (-> getList list for list in lists)

    @board.append elements
    @addPluginTaskButtons()
    opts =
      draggable: '.task'
      group: 'tasks'
      sort: true
      ghostClass: 'imdone-ghost'
      onEnd: (evt) ->
        id = evt.item.id
        pos = evt.newIndex
        list = evt.item.parentNode.dataset.list
        filePath = repo.getFullPath evt.item.dataset.path
        task = repo.getTask id
        repo.moveTasks [task], list, pos

    if @tasksSortables
      for sortable in @tasksSortables
        sortable.destroy() if sortable.el

    @tasksSortables = tasksSortables = []
    @find('.tasks').each ->
      tasksSortables.push(Sortable.create $(this).get(0), opts)
    @filter()
    @board.show()

  destroy: ->
    @emitter.emit 'did-destroy', @
    @imdoneRepo.destroy()
    @emitter.dispose()
    @remove()

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback

  openPath: (filePath, line) ->
    return unless filePath

    atom.workspace.open(filePath, split: 'left').done =>
      @moveCursorTo(line)

  moveCursorTo: (lineNumber) ->
    lineNumber = parseInt(lineNumber)

    if textEditor = atom.workspace.getActiveTextEditor()
      position = [lineNumber-1, 0]
      textEditor.setCursorBufferPosition(position, autoscroll: false)
      textEditor.scrollToCursorPosition(center: true)
