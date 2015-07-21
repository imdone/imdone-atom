{$, $$, $$$, ScrollView, TextEditorView} = require 'atom-space-pen-views'
{Emitter, Disposable, CompositeDisposable} = require 'atom'
ImdoneRepo = require 'imdone-core/lib/repository'
fsStore = require 'imdone-core/lib/mixins/repo-watched-fs-store'
path = require 'path'
util = require 'util'
Sortable = require 'sortablejs'
require('./jq-utils')($)

module.exports =
class ImdoneAtomView extends ScrollView
  @content: (params) ->
    @div class: "imdone-atom pane-item", =>
      @div outlet: "loading", class: "imdone-loading", =>
        @h4 "Loading #{path.basename(params.path)} Issues."
        @h4 "It's gonna be legen... wait for it."
        # #DONE:80 Update progress bar on repo load
        @progress class:'inline-block', outlet: "progress", max:100, value:1, style: "display:none;"
      @div outlet: "menu", class: "imdone-menu", =>
        @div click: "toggleMenu",  class: "imdone-menu-toggle imdone-toolbar-button", title: "show tools", =>
          @a href: "#", class: "icon icon-tools"
        @div class: "imdone-help imdone-toolbar-button", title: "syntax help", =>
          @a href: "https://github.com/imdone/imdone-core#task-formats", class: "icon icon-question"
        @div class: "imdone-filter", =>
          # @input outlet:"filterField", type:"text", placeholder: "filter tasks" #, keyup: "onFilterKeyup"
          @subview 'filterField', new TextEditorView(mini: true, placeholderText: "filter tasks")
          @div click: "clearFilter", class:"icon icon-x clear-filter"
        @ul outlet: "lists", class: "lists"
      @div outlet: "boardWrapper", class: "imdone-board-wrapper", =>
        @div outlet: "board", class: "imdone-board"

  getTitle: ->
    "#{path.basename(@path)} Issues"

  getIconName: ->
    # #DONE:10 Add icon to tab
    "checklist"

  getURI: ->
    @uri

  constructor: ({@path, @uri}) ->
    super
    @imdoneRepo = imdoneRepo = @getImdoneRepo()
    @handleEvents()
    imdoneRepo.on 'initialized', => @onRepoUpdate()
    imdoneRepo.on 'file.update', => @onRepoUpdate()
    imdoneRepo.on 'config.update', => imdoneRepo.refresh()
    imdoneRepo.on 'error', (err) => console.log('error:', err)

    imdoneRepo.fileStats (err, files) =>
      debugger
      if files.length > 1000
        @progress.show()
        imdoneRepo.on 'file.read', (data) =>
          complete = Math.ceil (data.completed/imdoneRepo.files.length)*100
          @progress.attr 'value', complete

    # #TODO:20 Check file stats.  If too many files, ask user to add excludes in config.json
    imdoneRepo.init()
    # setTimeout (->
    #   debugger
    #   imdoneRepo.init()
    # ), 2000

  handleEvents: ->
    repo = @imdoneRepo

    @on 'click', '.source-link',  (e) =>
      link = e.target
      @openPath(link.dataset.uri, link.dataset.line)

    @on 'click', '.toggle-list', (e) =>
      target = e.target
      name = target.dataset.list || target.parentElement.dataset.list
      if (repo.getList(name).hidden)
        repo.showList name
      else repo.hideList name

    @on 'click', '.delete-list', (e) =>
      target = e.target
      name = target.dataset.list || target.parentElement.dataset.list
      repo.removeList(name)

    editor = @filterField.getModel()
    editor.onDidStopChanging () =>
      @filter editor.getText()

    @on 'click', '.filter-link', (e) =>
      target = e.target
      filter = target.dataset.filter || target.parentElement.dataset.filter
      editor.setText filter

  toggleMenu: (event, element) ->
    @menu.toggleClass('open')
    @boardWrapper.toggleClass('shift')

  clearFilter: (event, element) ->
    @filterField.getModel().setText('')
    @board.find('.task').show()

  filter: (text) ->
    @lastFilter = text
    if text == ''
      @board.find('.task').show()
    else
      @board.find('.task').hide()
      @board.find(util.format('.task:regex(data-path,%s)', text)).show()
      @board.find(util.format('.task-full-text:containsRegex("%s")', text)).each( ->
        $(this).closest('.task').show()
      )

  getImdoneRepo: ->
    fsStore(new ImdoneRepo(@path))

  onRepoUpdate: ->
    @updateBoard()
    @updateMenu()

    @loading.hide()
    @menu.show()
    @boardWrapper.show();

  updateMenu: ->
    @listsSortable.destroy() if @listsSortable
    @lists.empty()

    repo = @imdoneRepo
    lists = repo.getLists()
    hiddenList = "hidden-list"

    getList = (list) ->
      $$ ->
        @li "data-list": list.name, =>
          @span class: "reorder icon icon-three-bars"
          @span class: "toggle-list  #{hiddenList if list.hidden}", "data-list": list.name, =>
            @span class: "icon icon-eye"
            @span "#{list.name} (#{repo.getTasksInList(list.name).length})"

    elements = (-> getList list for list in lists)

    @lists.append elements

    opts =
      draggable: 'li'
      handle: '.reorder'
      onEnd: (evt) ->
        name = evt.item.dataset.list
        pos = evt.newIndex
        repo.moveList name, pos

    @listsSortable = Sortable.create @lists.get(0), opts

  updateBoard: ->
    @board.empty()

    repo = @imdoneRepo
    lists = repo.getVisibleLists()
    width = 378*lists.length + "px"
    @board.css('width', width)
    # #DONE:20 Add task drag and drop support

    getTask = (task) =>
      contexts = task.getContext()
      tags = task.getTags()
      dateDue = task.getDateDue()
      dateCreated = task.getDateCreated()
      dateCompleted = task.getDateCompleted()
      $$$ ->
        @div class: 'task well', id: "#{task.id}", "data-path": task.source.path, =>
          @div class:'task-order', title: 'move task', =>
            @span class: 'badge', task.order
          @div class: 'task-full-text hidden', =>
            @raw task.getText()
          @div class: 'task-text', =>
            @raw task.getHtml(stripMeta: true, stripDates: true)
          # #DONE:60 Add todo.txt stuff like chrome app!
          if contexts
            @div =>
              for context, i in contexts
                do (context, i) =>
                  @a href:"#", title: "filter by #{context}", class: "filter-link", "data-filter": "@#{context}", =>
                    @span class: "task-context", context
                    @span ", " if (i < contexts.length-1)
          if tags
            @div =>
              for tag, i in tags
                do (tag, i) =>
                  @a href:"#", title: "filter by #{tag}", class: "filter-link", "data-filter": "\\+#{tag}", =>
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
                      @a href:"#", title: "filter by #{data.key}:#{data.value}", class: "filter-link", "data-filter": "#{data.key}:#{data.value}", =>
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
                      # #DOING:0 Implement #filter/*filterRegex* links
                      @a href:"#", title: "filter by completed on #{dateCompleted}", class: "filter-link", "data-filter": "x #{dateCompleted}", =>
                        @span class:"icon icon-light-bulb"
          @div class: 'task-source', =>
            @a class: 'source-link', title: 'go to task source', 'data-uri': "#{repo.getFullPath(task.source.path)}",
            'data-line': task.line, "#{task.source.path + ':' + task.line}"

    getList = (list) =>
      $$ ->
        tasks = repo.getTasksInList(list.name)
        @div class: 'top list well', =>
          @div class: 'list-name-wrapper well', =>
            @span class: 'list-name', list.name
            # #DONE:30 Add delete list icon if length is 0
            if (tasks.length < 1)
              @a href: '#', title: "delete #{list.name}", class: 'delete-list', "data-list": list.name, =>
                @span class:'icon icon-trashcan'
          @div class: 'tasks', "data-list":"#{list.name}", =>
            @raw getTask(task) for task in tasks

    elements = (-> getList list for list in lists)

    @board.append elements

    opts =
      draggable: '.task'
      group: 'tasks'
      handle: '.task-order'
      onEnd: (evt) ->
        id = evt.item.id
        pos = evt.newIndex
        list = evt.item.parentNode.dataset.list
        filePath = repo.getFullPath evt.item.dataset.path
        task = repo.getTask filePath, id
        repo.moveTasks [task], list, pos

    if @tasksSortables
      sortable.destroy() for sortable in @tasksSortables

    @tasksSortables = tasksSortables = []
    $('.tasks').each ->
      tasksSortables.push(Sortable.create $(this).get(0), opts)

  destroy: ->
    @imdoneRepo.destroy()
    @detach()


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
