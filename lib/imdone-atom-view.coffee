{$, $$, $$$, ScrollView} = require 'atom-space-pen-views'
{Emitter, Disposable, CompositeDisposable} = require 'atom'
ImdoneRepo = require 'imdone-core/lib/repository'
fsStore = require 'imdone-core/lib/mixins/repo-watched-fs-store'
path = require 'path'
sortable = require 'html5sortable'
$.fn.sortable = (options) ->
  sortable(this, options);

module.exports =
class ImdoneAtomView extends ScrollView
  @content: (params) ->
    @div class: "imdone-atom pane-item", =>
      @div outlet: "loading", class: "imdone-loading", =>
        @h4 "Loading #{path.basename(params.path)} Issues.  It's gonna be legen... wait for it."
        # DOING:20 Update progress bar on repo load
        @progress class:'inline-block', outlet: "progress", max:100, value:1, style: "display:none;"
      @div outlet: "menu", class: "imdone-menu", =>
        @div click: "toggleMenu",  class: "block imdone-menu-toggle", =>
          @span class: "icon icon-gear"
        @div outlet: "filter"
        @ul outlet: "lists", class: "lists"
      @div outlet: "boardWrapper", class: "imdone-board-wrapper", =>
        @div outlet: "board", class: "imdone-board"

  getTitle: ->
    "#{path.basename(@path)} Issues"

  getURI: ->
    @uri

  constructor: ({@path, @uri}) ->
    super
    @imdoneRepo = imdoneRepo = @getImdoneRepo()
    @handleEvents()
    imdoneRepo.on 'initialized', @onRepoUpdate.bind(this)
    imdoneRepo.on 'file.update', @onRepoUpdate.bind(this)
    imdoneRepo.on 'config.update', (-> imdoneRepo.refresh()).bind(this)

    imdoneRepo.fileStats ((err, files) ->
      if files.length > 1000
        @progress.show()
        imdoneRepo.on 'file.read', ((data) ->
          complete = Math.ceil (data.completed/imdoneRepo.files.length)*100
          @progress.attr 'value', complete
        ).bind(this)
    ).bind(this)

    # TODO:10 Maybe we need to check file stats first (For configuration)
    setTimeout (-> imdoneRepo.init()), 1000

  toggleMenu: (event, element) ->
    @menu.toggleClass('open')
    @boardWrapper.toggleClass('shift')

  getImdoneRepo: ->
    fsStore(new ImdoneRepo(@path))

  onRepoUpdate: ->
    @updateBoard()
    @updateMenu()

    @loading.hide()
    @menu.show()
    @boardWrapper.show();

  updateMenu: ->
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

    $('.lists').sortable(
      items: "li"
      handle:".reorder"
      forcePlaceholderSize: true
    ).bind('sortupdate', (e, ui) ->
      name = ui.item.attr "data-list"
      pos = ui.item.index()
      repo.moveList name, pos
    )

  updateBoard: ->
    @board.empty()

    repo = @imdoneRepo
    lists = repo.getVisibleLists()
    width = 378*lists.length + "px"
    @board.css('width', width)
    # TODO:20 Add task drag and drop support

    getTask = (task) ->
      $$$ ->
        @div class: 'inset-panel padded task well', id: "#{task.id}", =>
          @div class:'task-order', =>
            @span class: 'badge', task.order
          @div class: 'task-text', =>
            @raw task.getHtml()
          @div class: 'task-source', =>
            # DOING:10 Add todo.txt stuff like chrome app!
            @a class: 'source-link', 'data-uri': "#{repo.getFullPath(task.source.path)}",
            'data-line': task.line, "#{task.source.path + ':' + task.line}"

    getList = (list) ->
      $$ ->
        @div class: "top list well", =>
          @div class: 'panel', =>
            @div class: 'list-name well', list.name
            @div class: 'panel-body tasks', "data-list":"#{list.name}", =>
              @raw getTask(task) for task in repo.getTasksInList(list.name)

    elements = (-> getList list for list in lists)

    @board.append elements

  destroy: ->
    @detach()

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
