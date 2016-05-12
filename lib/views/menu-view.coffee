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
        # READY:160 Show logged in user and avatar here
        @div class: "imdone-filter", =>
          @subview 'filterField', new TextEditorView(mini: true, placeholderText: "filter tasks")
          @div click: "clearFilter", class:"icon icon-x clear-filter", outlet:'$clearFilter'
        @div class:'lists-wrapper', outlet:'$listWrapper', =>
          @ul outlet: "lists", class: "lists"
        # BACKLOG:0 Add saved filters
        @div class: "imdone-toolbar", =>
          @div class: "imdone-profile imdone-toolbar-button", outlet: "$profile", =>
            @div outlet:'$login', class:'text-success imdone-icon', title:'Blast off! login and share', =>
              # TODO: Replace this with imdone-logo-dark.svg [Icon System with SVG Sprites | CSS-Tricks](https://css-tricks.com/svg-sprites-use-better-icon-fonts/)
              # - [Icon System with SVG Sprites | CSS-Tricks](https://css-tricks.com/svg-sprites-use-better-icon-fonts/)
              # - [SVG `symbol` a Good Choice for Icons | CSS-Tricks](https://css-tricks.com/svg-symbol-good-choice-icons/)
              @a click:'openShare', href: "#", =>
                @tag 'svg', class: 'icon', =>
                  @tag 'use', "xlink:href":"#imdone-logo-icon"
            @div class:"profile-image", outlet:'$profileImage', click:'openShare', style:'display:none;'
          @div class: "menu-sep-space-3x"
          # BACKLOG: Add config opener and change the icon for tools to wrench or list `atom.workspace.open 'atom://config/packages/imdone-atom'` <https://github.com/mrodalgaard/atom-todo-show/blob/804cced598daceb1c5f870ae87a241bbf31e2f17/lib/todo-options-view.coffee#L49>
          @div click: "toggleMenu", class: "imdone-menu-toggle imdone-toolbar-button", title: "Lists and filter", =>
            @a href: "#", class: "icon icon-list-unordered"
          @div click: "newList", class: "new-list-open imdone-toolbar-button", title: "I need another list", =>
            @a href: "#", class: "icon icon-plus"
          # DONE:190 Add a link to open filtered files issue:49
          @div click: "openVisible", outlet: "zap", class: "imdone-toolbar-button text-success", title: "Zap! (open visible files)", =>
            @a href: "#", class: "icon icon-zap"
          @div class: "imdone-help imdone-toolbar-button", title: "Help, please!", =>
            @a href: "https://github.com/imdone/imdone-core#task-formats", class: "icon icon-question"
          @div class: "menu-sep-space-2x"
          @div class: "imdone-project-plugins"
            # DOING: Add the plugin buttons here

  initialize: ({@imdoneRepo, @path, @uri}) ->
    path = require 'path'
    util = require 'util'
    Sortable = require 'sortablejs'
    Client = require '../services/imdoneio-client'
    require('./jq-utils')($)
    @client = Client.instance
    return @authenticated() if @client.isAuthenticated()
    @client.authFromStorage


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
    title = "Share Settings &#x0aImdone Account: #{user.profile.name || user.handle} &#x0a(#{user.email})"
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
