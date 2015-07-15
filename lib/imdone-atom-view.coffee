{$, $$, $$$, ScrollView} = require 'atom-space-pen-views'
{Emitter, Disposable, CompositeDisposable} = require 'atom'
ImdoneRepo = require 'imdone-core/lib/repository'
fsStore = require 'imdone-core/lib/mixins/repo-watched-fs-store'
path = require 'path'
jquery = require 'jquery'
require 'jquery-ui/draggable'
require 'jquery-ui/droppable'
require 'jquery-ui/sortable'

module.exports =
class ImdoneAtomView extends ScrollView
  @content: (params) ->
    @div class: "imdone-atom pane-item", =>
      @div outlet: "loading", class: "imdone-loading", =>
        @h4 "Loading #{path.basename(params.path)} Issues..."
        # DOING:20 Update progress bar on repo load
        @progress class:'inline-block', outlet: "progress", max:100, value:50
      @div outlet: "board", class: "imdone-board"

  getTitle: ->
    "#{path.basename(@path)} Issues"

  getURI: ->
    @uri

  constructor: ({@path, @uri}) ->
    super
    @imdoneRepo = imdoneRepo = @getImdoneRepo()
    imdoneRepo.on 'initialized', @onRepoUpdate.bind(this)
    imdoneRepo.on 'file.update', @onRepoUpdate.bind(this)
    imdoneRepo.on 'config.update', (->
      @board.hide()
      @loading.show()
      imdoneRepo.refresh()).bind(this)

    # TODO:10 Maybe we need to check file stats first (For configuration)
    setTimeout (-> imdoneRepo.init()), 1000

  getImdoneRepo: ->
    fsStore(new ImdoneRepo(@path))

  onRepoUpdate: ->
    @loading.hide()
    @board.show().empty()

    repo = @imdoneRepo
    lists = repo.getVisibleLists()
    width = 378*lists.length + "px"
    @board.css('width', width)
    # TODO:20 Add task drag and drop support

    getTask = (task) ->
      $$$ ->
        @div class: 'inset-panel padded task well', id: "#{task.id}", =>
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

    jquery('.tasks').sortable(
      delay: 300
      axis: "y"
      items: ".task"
      containment: "parent"
      tolerance: "pointer"
      # stop: function(e, ui) {
      #   loading.show();
      #   var name = ui.item.attr("data-list");
      #   var pos = ui.item.index();
      #   self.model.moveList(name, pos, loading.hide);
      # }
    ).disableSelection()

  initialize: ->
    @handleEvents()

  destroy: ->
    @detach()

  handleEvents: ->
    @on 'click', '.source-link',  (e) =>
      link = e.target
      @openPath(link.dataset.uri, link.dataset.line)

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
