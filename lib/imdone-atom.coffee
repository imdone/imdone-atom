path                = require 'path'
url                 = null
CompositeDisposable = null
_                   = null
ImdoneAtomView      = null
imdoneHelper        = null
configHelper        = require './services/imdone-config'

module.exports = ImdoneAtom =
  config:
    showLoginOnLaunch:
      order: 1
      description: "Display imdone.io login panel on startup if user is not logged in."
      type: 'boolean'
      default: true
    useAlternateFileWatcher:
      order: 2
      description: "If your board won't update when you edit files, then try the alternate file watcher"
      type: 'boolean'
      default: false
    showTagsInline:
      order: 3
      description: 'Display inline tag and context links in task text?'
      type: 'boolean'
      default: false
    maxFilesPrompt:
      order: 4
      description: 'How many files is too many to parse without prompting to add ignores?'
      type: 'integer'
      default: 2000
      minimum: 1000
      maximum: 10000
    excludeVcsIgnoredPaths:
      order: 5
      description: 'Exclude files that are ignored by your version control system'
      type: 'boolean'
      default: true
    showNotifications:
      order: 6
      description: 'Show notifications upon clicking task source link.'
      type: 'boolean'
      default: false
    zoomLevel:
      order: 7
      description: 'Set the default zoom level on startup'
      type: 'number'
      default: 1
    openIn:
      order: 8
      title: 'File Opener'
      description: 'Open files in a different IDE or editor'
      type: 'object'
      properties:
        enable:
          order: 1
          title: 'Enable file opener'
          type: 'boolean'
          default: false
        port:
          order: 2
          title: 'File Opener Port'
          description: 'Port the file opener communicates on'
          type: 'integer'
          default: 9799
        intellij:
          order: 3
          description: '[Glob pattern](https://github.com/isaacs/node-glob) for files that should open in Intellij.'
          type: 'string'
          default: 'Glob pattern'
    todaysJournal:
      order: 9,
      type: 'object'
      properties:
        directory:
          description: 'Where do you want your global journal files to live?'
          type: 'string'
          default: "#{path.join(process.env.HOME || process.env.USERPROFILE, 'notes')}"
        fileNameTemplate:
          description: 'How do you want your global journal files to be named?'
          type: 'string'
          default: '${date}.md'
        projectFileNameTemplate:
          description: 'How do you want your project journal files to be named?'
          type: 'string'
          default: 'journal/${month}/${date}.md'
        dateFormat:
          description: 'How would you like your `date` variable formatted for use in directory or file name template?'
          type: 'string'
          default: 'YYYY-MM-DD'
        monthFormat:
          description: 'How would you like your `month` variable formatted for use in directory or file name template?'
          type: 'string'
          default: 'YYYY-MM'
  subscriptions: null
  #
  # serialize: ->
  #   views = atom.workspace.getPaneItems().filter (view) -> view instanceof ImdoneAtomView
  #   serialized = views.map (view) -> view.serialize()
  #   #console.log 'serializedViews:', serialized
  #   serialized

  activate: (state) ->

    _ = require 'lodash'
    url = require 'url'
    ImdoneAtomView ?= require './views/imdone-atom-view'
    {CompositeDisposable} = require 'atom'
    _.templateSettings.interpolate = /\${([\s\S]+?)}/g;
    # state.forEach (view) -> atom.deserializers.deserialize(view) if state
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.commands.add 'atom-workspace', "imdone-atom:tasks", (evt) =>
      evt.stopPropagation()
      evt.stopImmediatePropagation()
      target = evt.target
      projectRoot = target.closest '.project-root'
      if projectRoot
        projectPath = projectRoot.getElementsByClassName('name')[0].dataset.path
      @tasks(projectPath)

    @subscriptions.add atom.commands.add 'atom-workspace', "imdone-atom:todays-journal", (evt) =>
      evt.stopPropagation()
      evt.stopImmediatePropagation()
      @openJournalFile()

    @subscriptions.add atom.commands.add 'atom-workspace', "imdone-atom:todays-project-journal", (evt) =>
      evt.stopPropagation()
      evt.stopImmediatePropagation()
      @openJournalFile(@getCurrentProject())

    @subscriptions.add atom.commands.add 'atom-workspace', "imdone-atom:export", (evt) =>
      evt.stopPropagation()
      evt.stopImmediatePropagation()
      @openExport(@getCurrentProject())

    @subscriptions.add atom.commands.add 'atom-workspace', 'imdone-atom:board-zoom-in', (evt) => @zoom 'in'

    @subscriptions.add atom.commands.add 'atom-workspace', 'imdone-atom:board-zoom-out', (evt) => @zoom 'out'

    atom.workspace.addOpener (uriToOpen) =>
      {protocol, host, pathname} = url.parse(uriToOpen)
      return unless protocol is 'imdone:'
      @viewForUri(uriToOpen)

    @fileService = require('./services/file-service').init configHelper.getSettings().openIn.port



  emit: (name, data) ->
    active = atom.workspace.getActivePaneItem()
    return unless active instanceof ImdoneAtomView
    active.emitter.emit name, data

  zoom: (dir) -> @emit 'zoom', dir

  tasks: (projectPath) ->
    previousActivePane = atom.workspace.getActivePane()
    uri = @uriForProject(projectPath)
    return unless uri
    atom.workspace.open(uri, searchAllPanes: true).then (imdoneAtomView) =>
      return unless imdoneAtomView instanceof ImdoneAtomView
      previousActivePane.activate()

  deactivate: ->
    imdoneHelper = require './services/imdone-helper'
    imdoneHelper.destroyRepos()
    @subscriptions.dispose()

  getCurrentProject: ->
    paths = atom.project.getPaths()
    active = atom.workspace.getActivePaneItem()
    return unless paths.length > 0 || active.selectedPath
    return active.getSelectedEntries()[0].closest('.project-root').getPath() if active && active.selectedPath
    return active.imdoneRepo.getPath() if active && active.imdoneRepo
    if active && active.getPath && active.getPath()
      return projectPath for projectPath in paths when active.getPath().indexOf(projectPath+path.sep) == 0
    else
      paths[0]

  provideService: -> require './services/plugin-manager'

  openExport: (projectDir) ->
    fs = require 'fs'
    imdoneHelper ?= require './services/imdone-helper'
    if projectDir
      repo = imdoneHelper.getRepo projectDir
      file = path.join projectDir, 'imdone-export.json'
      json = JSON.stringify(repo.getTasks(), null, 2);
      fs.writeFile file, json, (err) ->
        return if err
        atom.workspace.open(file)

  # DOING: Journal-names id:152
  # https://github.com/imdone/imdone-atom/issues/81
  # https://github.com/xeor
  # <thanks>`imdone` almost hit a PERFECT hit on my current workflow. Looking very much forward to whats next!</thanks>
  # In the settings, it supports journal filenames based on text and one variable (`${DATE}`). Would it be, or is it in the pipeline to expand journal creations to support more advanced name-templates? Example, based on highlighed text, a popup to ask for part of the filenames, and so on.
  # I usually ends up taking a lot of notes during the day, all in the format "YYYY-MM-DD notename here.md".
  # - Use modalPanel
  # - [Create your first Atom package | Blog Eleven Labs](https://blog.eleven-labs.com/en/create-atom-package/)
  # ```coffeescript
  # regex = /\${(\w*?)}/g
  # vars = []
  # while (result = regex.exec(t))
  #   variable = result[1]
  #   vars.push(variable) if (!data[variable])
  # ```
  template: (t) ->
    moment = require 'moment'
    config = configHelper.getSettings().todaysJournal
    date = moment().format config.dateFormat
    month = moment().format config.monthFormat
    data = {date, month}
    _.template(t)(data)

  openJournalFile: (projectDir) ->
    mkdirp = require 'mkdirp'
    config = configHelper.getSettings().todaysJournal

    if projectDir
      file = @template(config.projectFileNameTemplate)
      atom.workspace.open(path.join projectDir, file)
    else
      file = @template(config.fileNameTemplate)
      dir = config.directory
      filePath = path.join dir, file
      mkdirp dir, (err) ->
        if (err)
          atom.notifications.addError "Can't open journal file #{filePath}"
          return;
        atom.project.addPath dir
        atom.workspace.open filePath

  uriForProject: (projectPath) ->
    projectPath = projectPath || @getCurrentProject()
    return unless projectPath
    projectPath = encodeURIComponent(projectPath)
    'imdone://tasks/' + projectPath

  viewForUri: (uri) ->
    {protocol, host, pathname} = url.parse(uri)
    return unless pathname
    pathname = decodeURIComponent(pathname.split('/')[1])
    @createImdoneAtomView(path: pathname, uri: uri)

  createImdoneAtomView: ({path, uri}) ->
    ImdoneAtomView ?= require './views/imdone-atom-view'
    imdoneHelper ?= require './services/imdone-helper'
    repo = imdoneHelper.getRepo path, uri
    view = new ImdoneAtomView(imdoneRepo: repo, path: path, uri: uri)
