{$, $$, $$$, View, TextEditorView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
path = null
util = null
Sortable = null
Client = null

module.exports =
class MenuView extends View
  @content: (params) ->
    @div class: "imdone-menu", =>
      @div class: "imdone-menu-inner", =>
        # READY:110 Show logged in user and avatar here
        @div class: "imdone-profile", outlet: "$profile", =>
          @div outlet:'$login', class:'text-success', title:'Blast off! login and sync tasks', =>
            @a click:'openShare', href: "#", class: 'icon icon-rocket'
          @div outlet:'$profileImage', click:'openShare', style:'display:none;'
        @div class: "imdone-filter", =>
          @subview 'filterField', new TextEditorView(mini: true, placeholderText: "filter tasks")
          @div click: "clearFilter", class:"icon icon-x clear-filter", outlet:'$clearFilter'
        @div class:'lists-wrapper', outlet:'$listWrapper', =>
          @ul outlet: "lists", class: "lists"
        # BACKLOG:0 Add saved filters
        @div class: "imdone-toolbar", =>
          @div click: "toggleMenu", class: "imdone-menu-toggle imdone-toolbar-button", title: "tools baby!", =>
            @a href: "#", class: "icon icon-gear"
          @div click: "newList", class: "new-list-open imdone-toolbar-button", title: "I need another list", =>
            @a href: "#", class: "icon icon-plus"
          # DONE:190 Add a link to open filtered files issue:49
          @div click: "openVisible", outlet: "zap", class: "imdone-toolbar-button text-success", title: "Zap! (open visible files)", =>
            @a href: "#", class: "icon icon-zap"
          @div class: "imdone-help imdone-toolbar-button", title: "Help, please!", =>
            @a href: "https://github.com/imdone/imdone-core#task-formats", class: "icon icon-question"
          @div class: "imdone-project-plugins"

  initialize: ({@imdoneRepo, @path, @uri}) ->
    path = require 'path'
    util = require 'util'
    Sortable = require 'sortablejs'
    Client = require '../services/imdoneio-client'
    require('./jq-utils')($)
    @client = Client.instance
    @authenticated() if @client.isAuthenticated()

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

  openVisible: ->
    @emitter.emit 'visible.open'

  emitRepoChange: ->
    @emitter.emit 'repo.change'

  handleEvents: (@emitter) ->
    if @initialized || !@emitter then return else @initialized = true
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
    @client.on 'authenticated', => @authenticated()

  authenticated: ->
    console.log 'authenticated:', @client.user
    user = @client.user
    title = "Sync Tasks &#x0aImdone Account: #{user.profile.name || user.handle} &#x0a(#{user.email})"
    src = if user.profile.picture then user.profile.picture else user.thumbnail
    @$login.hide()
    @$profileImage.html($$ -> @img class:'img-circle share-btn', src: src, title: title).show()

  openShare: ->
    @emitter.emit 'share'

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
