{$, $$, $$$, View, TextEditorView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
path = require 'path'
util = require 'util'
Sortable = require 'sortablejs'
require('./jq-utils')($)

module.exports =
class MenuView extends View
  @content: (params) ->
    @div class: "imdone-menu", =>
      @div class: "imdone-menu-inner", =>
        @div class: "imdone-toolbar", =>
          @div click: "toggleMenu", class: "imdone-menu-toggle imdone-toolbar-button", title: "tools baby!", =>
            @a href: "#", class: "icon icon-gear"
          @div click: "newList", class: "new-list-open imdone-toolbar-button", title: "I need another list", =>
            @a href: "#", class: "icon icon-plus"
          # DONE:170 Add a link to open filtered files issue:49
          @div click: "share", class: "imdone-toolbar-button text-success", title: "Whoosh! (share visible tasks)", =>
            @a href: "#", class: "icon icon-rocket"
          @div click: "openFiltered", outlet: "zap", class: "imdone-toolbar-button text-success", title: "Zap! (open filtered files)", style: "display:none;", =>
            @a href: "#", class: "icon icon-zap"
          @div class: "imdone-help imdone-toolbar-button", title: "Help, please!", =>
            @a href: "https://github.com/imdone/imdone-core#task-formats", class: "icon icon-question"
          @div class: "imdone-project-plugins"
        @div class: "imdone-filter", =>
          @subview 'filterField', new TextEditorView(mini: true, placeholderText: "filter tasks")
          @div click: "clearFilter", class:"icon icon-x clear-filter"
        @div class:'lists-wrapper', =>
          @ul outlet: "lists", class: "lists"
        # TODO:70 Add saved filters

  initialize: ({@imdoneRepo, @path, @uri}) ->
    @emitter = new Emitter
    @handleEvents()

  toggleMenu: (event, element) ->
    @toggleClass 'open'
    @emitter.emit 'menu.toggle'

  getFilterEditor: ->
    @filterField.getModel()

  setFilter: (text) ->
    @getFilterEditor().setText text

  getFilter: ->
    @getFilterEditor().getText()

  clearFilter: (event, element) ->
    @getFilterEditor().setText('')
    @emitter.emit 'filter.clear'

  newList: ->
    @emitter.emit 'list.new'

  openFiltered: ->
    # TODO:30 Zap should open visible task files but prompt if there are more than 10 (configurable) +feature
    @emitter.emit 'filter.open'

  share: ->
    @emitter.emit 'share'

  emitRepoChange: ->
    @emitter.emit 'repo.change'

  handleEvents: ->
    repo = @imdoneRepo
    @on 'click', '.toggle-list', (e) =>
      @emitRepoChange()
      target = e.target
      name = target.dataset.list || target.parentElement.dataset.list
      if (repo.getList(name).hidden)
        repo.showList name
      else repo.hideList name

    @getFilterEditor().onDidStopChanging () =>
      @emitter.emit 'filter', @getFilter()

    @imdoneRepo.on 'initialized', =>
      @updateMenu()
    @imdoneRepo.on 'list.modified', =>
      @updateMenu()
    @imdoneRepo.on 'file.update', =>
      @updateMenu()
    @imdoneRepo.on 'tasks.move', =>
      @updateMenu()

    @emitter.on 'filter.tasks', (tasks) =>
      if tasks.length > 0
        @zap.show()
      else
        @zap.hide()

  updateMenu: ->
    return unless @imdoneRepo
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
      ghostClass: 'imdone-ghost'
      onEnd: (evt) =>
        @emitRepoChange()
        name = evt.item.dataset.list
        pos = evt.newIndex
        repo.moveList name, pos

    @listsSortable = Sortable.create @lists.get(0), opts
