{$, $$, $$$, View, TextEditorView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
path = null
util = null
Sortable = null
Client = null
config = require '../../config'
menuOpenClass = "icon-chevron-left"
menuClosedClass = "icon-chevron-right"

module.exports =
class MenuView extends View
  @content: (params) ->
    @div class: "imdone-menu", =>
      @div class: "imdone-menu-inner", =>
        # READY: Show logged in user and avatar here
        @div class: "imdone-filter", =>
          @subview 'filterField', new TextEditorView(mini: true, placeholderText: "filter tasks")
          @div click: "clearFilter", class:"icon icon-x clear-filter", outlet:'$clearFilter'
        @div class:'lists-wrapper', outlet:'$listWrapper', =>
          @ul outlet: "lists", class: "lists"
        # BACKLOG: Save my favorite filters
        @div click: "toggleMenu", outlet:"$menuButton", class: "imdone-menu-toggle imdone-toolbar-button", title: "Lists and filter", =>
          @a href: "#", class: "icon #{menuClosedClass}"
        @div outlet: '$toolbar', class: "imdone-toolbar", =>
          # DONE: Replace this with imdone-logo-dark.svg [Icon System with SVG Sprites | CSS-Tricks](https://css-tricks.com/svg-sprites-use-better-icon-fonts/)
          # - [Icon System with SVG Sprites | CSS-Tricks](https://css-tricks.com/svg-sprites-use-better-icon-fonts/)
          # - [SVG `symbol` a Good Choice for Icons | CSS-Tricks](https://css-tricks.com/svg-symbol-good-choice-icons/)
          # BACKLOG: Open package config with a button click `atom.workspace.open 'atom://config/packages/imdone-atom'` <https://github.com/mrodalgaard/atom-todo-show/blob/804cced598daceb1c5f870ae87a241bbf31e2f17/lib/todo-options-view.coffee#L49> +feature gh:177
          # @div click: "toggleMenu", outlet:"$menuButton", class: "imdone-menu-toggle imdone-toolbar-button", title: "Lists and filter", =>
          #   @a href: "#", class: "icon #{menuClosedClass}"
          # @div class: "menu-sep-space-2x"
          @div click: "newList", class: "new-list-open imdone-toolbar-button", title: "I need another list", =>
            @a href: "#", =>
              @i class: "icon icon-plus toolbar-icon"
              @span class:'tool-text', 'Add a new list'
          # DONE: Add a link to open filtered files gh:49
          @div click: "openVisible", outlet: "zap", class: "imdone-toolbar-button", title: "Zap! (open visible files)", =>
            @a href: "#", =>
              @i class: "icon icon-zap toolbar-icon"
              @span class:'tool-text', 'Open files for visible tasks'
          @div class: "imdone-help imdone-toolbar-button", title: "Help, please!", =>
            @a href: "https://github.com/imdone/imdone-core#task-formats", =>
              @i class: "icon icon-question toolbar-icon"
              @span class:'tool-text', 'Help'
          @div class: "menu-sep-space-2x"
          @div outlet:'$projectButtons', class: "imdone-project-plugins", style: "disaply:none"
          @div outlet:'$projectButtonsSpace', class: "imdone-project-plugins-spacer menu-sep-space-2x", style: "display:none;"

          @div outlet: "$imdoneioButtons", style: "display:none;", =>
            @div click: "openShare", class: "imdone-toolbar-button", title: "Project TODOBOTs", =>
              @a href: "#", =>
                @i class: "icon icon-settings toolbar-icon"
                @span class:'tool-text', 'Project TODOBOTs'

            @div outlet:'$disconnect', click: 'disconnectImdoneio', class: 'imdone-toolbar-button', style: 'display: none;', title: 'Disconnect from imdone.io', =>
              @a href: '#', =>
                @i class:"icon icon-stop"
                @span class:'tool-text', 'Disconnect from imdone.io'

            @div outlet: '$logOff', click: "logOff", class: "imdone-toolbar-button", title: 'Log out', =>
              @a href: '#', =>
                @i class:"icon icon-log-out"
                @span class:'tool-text', 'Sign out'

            @div outlet: '$account', class: "imdone-profile imdone-toolbar-button", titel: "Account", =>
              @a href: "#{config.baseUrl}/account", =>
                @i class:"profile-image icon", outlet:'$profileImage'
                @span class:'tool-text', 'Account'

          @div outlet:'$login', class:'imdone-icon imdone-toolbar-button', title:'login to imdone.io', =>
            @a click:'openLogin', href: "#", =>
              @i class:'icon', =>
                @tag 'svg', => @tag 'use', "xlink:href":"#imdone-logo-icon"
              @span class:'tool-text', 'Login'

          # BACKLOG: Add the plugin project buttons

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
    @$disconnect.show() if @imdoneRepo.isImdoneIOProject()

  addPluginProjectButtons: () ->
    @$projectButtons.empty()
    plugins = @imdoneRepo.getPlugins()
    if plugins
      @$projectButtons.show().append plugin.projectButtons() for plugin in plugins
      @$projectButtonsSpace.show()
    else
      @$projectButtons.hide()
      @$projectButtonsSpace.hide()

  showSpinner: () -> @spinner.show()

  hideSpinner: () -> @spinner.hide()

  toggleMenu: (event, element) ->
    @toggleClass 'open'
    @$toolbar.toggleClass 'open'
    isOpening = @hasClass 'open'
    $link = @$menuButton.find 'a'
    $link.removeClass "#{menuOpenClass} #{menuClosedClass}"
    $link.addClass menuOpenClass if isOpening
    $link.addClass menuClosedClass unless isOpening

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

  # NOTE: @defunkt This issue was created in @atom with @imdone.  Stay in the flow~~~~~~~ +discuss gh:171
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

    @emitter.on 'project.found', => @$disconnect.show()
    @emitter.on 'project.not-found', => @$disconnect.hide()
    @emitter.on 'project.removed', => @$disconnect.hide()

    @emitter.on 'initialized', => @updateMenu()
    @emitter.on 'list.modified', => @updateMenu()
    @emitter.on 'file.update', => @updateMenu()
    @emitter.on 'tasks.moved', => @updateMenu()

    @emitter.on 'authenticated', => @authenticated()
    @emitter.on 'unauthenticated', => @unauthenticated()
    @emitter.on 'unavailable', => @unauthenticated()

  authenticated: ->
    #console.log 'authenticated:', @client.user
    user = @client.user
    crlf = "&#x0a;"
    title = "Account: #{user.profile.name || user.handle} &#x0a(#{user.email})"
    src = if user.profile.picture then user.profile.picture else user.thumbnail
    @$login.hide()
    @$profileImage.html($$ -> @img class:'img-circle share-btn', src: src)
    @$account.attr 'title', title
    @$imdoneioButtons.show()
    @$disconnect.hide() unless @imdoneRepo.isImdoneIOProject()


  unauthenticated: ->
    @$login.show()
    @$imdoneioButtons.hide()

  openShare: -> @emitter.emit 'share'

  openLogin: ->
    @client.authFromStorage (err) =>
      #console.log err
      @emitter.emit 'login' if err

  logOff: ->
    @client.logoff()
    @emitter.emit "logoff"

  disconnectImdoneio: (e) ->
    @imdoneRepo.disableProject() if window.confirm "Do you really want to stop using imdone.io with #{@imdoneRepo.getProjectName()}?"


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
