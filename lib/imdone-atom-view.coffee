{$, $$, $$$, ScrollView} = require 'atom-space-pen-views'
{Emitter, Disposable, CompositeDisposable} = require 'atom'
ImdoneRepo = require 'imdone-core/lib/repository'
fsStore = require 'imdone-core/lib/mixins/repo-fs-store'
path = require 'path'

module.exports =
class ImdoneAtomView extends ScrollView
  @content: (params) ->
    @div class: "imdone-atom", =>
      @div outlet: "loading", class: "imdone-loading", =>
        @h4 "Loading #{path.basename(params.path)} Issues..."
      @div outlet: "board", class: "imdone-board"

  getTitle: ->
    "#{path.basename(@path)} Issues"

  constructor: ({@path}) ->
    super
    # register the atomPanel tag
    @imdoneRepo = imdoneRepo = @getImdoneRepo()
    imdoneRepo.on 'initialized', @onRepoUpdate.bind(this)
    # TODO:0 Maybe we need to check file stats first (For configuration)
    setTimeout (-> imdoneRepo.init()), 1000

  getImdoneRepo: ->
    fsStore(new ImdoneRepo(@path))

  onRepoUpdate: ->
    @loading.hide()
    lists = @imdoneRepo.getLists()
    repo = @imdoneRepo

    getTask = (task) ->
      $$$ ->
        @div class: 'inset-panel padded', id: "#{task.id}", =>
          @raw task.getHtml()

    getList = (list) ->
      $$ ->
        @div class: 'top list', =>
          @div class: 'padded', =>
            @div class: 'panel', =>
              @div class: 'panel-heading', list.name
              @div class: 'panel-body tasks', "data-list":"#{list.name}", =>
                @raw getTask(task) for task in repo.getTasksInList(list.name)
                # @div class: 'inset-panel padded', id: "#{task.id}", =>
                #   @raw(task.getHtml()) for task in repo.getTasksInList(list.name)
          # @h2 list.name
          # @ol =>
          #   @li task.getText() for task in repo.getTasksInList(list.name)

    elements = (-> getList list for list in lists)

    @board.append elements
