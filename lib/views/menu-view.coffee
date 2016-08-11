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
        # READY:240 Show logged in user and avatar here id:89
        @div class: "imdone-filter", =>
          @subview 'filterField', new TextEditorView(mini: true, placeholderText: "filter tasks")
          @div click: "clearFilter", class:"icon icon-x clear-filter", outlet:'$clearFilter'
        @div class:'lists-wrapper', outlet:'$listWrapper', =>
          @ul outlet: "lists", class: "lists"
        # BACKLOG:160 Save my favorite filters +story id:90
        @div class: "imdone-toolbar", =>
          # DONE:0 Replace this with imdone-logo-dark.svg [Icon System with SVG Sprites | CSS-Tricks](https://css-tricks.com/svg-sprites-use-better-icon-fonts/) id:91
          # - [Icon System with SVG Sprites | CSS-Tricks](https://css-tricks.com/svg-sprites-use-better-icon-fonts/)
          # - [SVG `symbol` a Good Choice for Icons | CSS-Tricks](https://css-tricks.com/svg-symbol-good-choice-icons/)
          @div class: "menu-sep-space-2x"
          # BACKLOG:140 Open package config with a button click `atom.workspace.open 'atom://config/packages/imdone-atom'` <https://github.com/mrodalgaard/atom-todo-show/blob/804cced598daceb1c5f870ae87a241bbf31e2f17/lib/todo-options-view.coffee#L49> id:92
          @div click: "toggleMenu", class: "imdone-menu-toggle imdone-toolbar-button", title: "Lists and filter", =>
            @a href: "#", class: "icon icon-list-unordered"
          @div click: "newList", class: "new-list-open imdone-toolbar-button", title: "I need another list", =>
            @a href: "#", class: "icon icon-plus"
          # DONE:0 Add a link to open filtered files issue:49 id:93
          @div click: "openVisible", outlet: "zap", class: "imdone-toolbar-button text-success", title: "Zap! (open visible files)", =>
            @a href: "#", class: "icon icon-zap"
          @div class: "imdone-help imdone-toolbar-button", title: "Help, please!", =>
            @a href: "https://github.com/imdone/imdone-core#task-formats", class: "icon icon-question"
          @div class: "menu-sep-space-2x"
          @div outlet:'$login', class:'text-success imdone-icon', title:'login to imdone.io', =>
            @a click:'openLogin', href: "#", =>
              @tag 'svg', class: 'icon', =>
                @tag 'use', "xlink:href":"#imdone-logo-icon"
          @div outlet: '$logOff', click: "logOff", class: "imdone-profile imdone-toolbar-button", =>
            @div class:"profile-image", outlet:'$profileImage'
          @div click:'openProjectSettings', outlet:'$projectSettings', class:'imdone-toolbar-button', title:'Project Settings', style: "display:none;", =>
            @a href: "#", class:"icon icon-settings"
          @div outlet: "$imdoneioButtons", style: "display:none;", =>
            @div click: "openTeamSettings", class: "imdone-toolbar-button", title:"Team Settings", =>
              @a href: "#", class: "icon icon-organization"
            @div click: "openShare", class: "imdone-toolbar-button", title: "Project Integrations", =>
              @a href: "#", class: "icon icon-plug"
          @div class: "imdone-project-plugins"
          # BACKLOG:60 Add the plugin project buttons id:94
          @div outlet: "spinner", class: "spinner imdone-toolbar-button", style:'display:none;', =>
            @span class: 'loading loading-spinner-tiny inline-block'

  initialize: ({@imdoneRepo, @path, @uri}) ->
    path = require 'path'
    util = require 'util'
    Sortable = require 'sortablejs'
    Client = require '../services/imdoneio-client'
    require('./jq-utils')($)
    @client = Client.instance
    return @authenticated() if @client.isAuthenticated()
    @client.authFromStorage

  addPluginProjectButtons: (plugins) ->

  showSpinner: () -> @spinner.show()

  hideSpinner: () -> @spinner.hide()

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
    @imdoneRepo.on 'tasks.moved', =>
      @updateMenu()
    @client.on 'authenticated', => @authenticated()
    @client.on 'unauthenticated', => @unauthenticated()

  authenticated: ->
    console.log 'authenticated:', @client.user
    user = @client.user
    title = "Sign out &#x0aimdone.io Account: #{user.profile.name || user.handle} &#x0a(#{user.email})"
    src = if user.profile.picture then user.profile.picture else user.thumbnail
    @$login.hide()
    @$logOff.show();
    @$profileImage.html($$ -> @img class:'img-circle share-btn', src: src, title: title)
    @$projectSettings.show()
    @$imdoneioButtons.show()

  unauthenticated: ->
    @$login.show()
    @$logOff.hide()
    @$projectSettings.hide()
    @$imdoneioButtons.hide()

  openShare: -> @emitter.emit 'share'

  openLogin: -> @emitter.emit 'login'

  openProjectSettings: -> @emitter.emit 'project.settings'

  openTeamSettings: -> @emitter.emit 'project.team-settings'

  logOff: ->
    @client.logoff()
    @emitter.emit "logoff"

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
