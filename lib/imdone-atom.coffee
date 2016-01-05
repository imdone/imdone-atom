ImdoneAtomView = require './imdone-atom-view'
url = require 'url'
{CompositeDisposable} = require 'atom'
path = require 'path'
moment = require 'moment'
mkdirp = require 'mkdirp'
imdoneHelper = require './imdone-helper'
fileService = require './file-service'

module.exports = ImdoneAtom =
  config:
    maxFilesPrompt:
      description: 'How many files is too many to parse without prompting?'
      type: 'integer'
      default: 2000
      minimum: 1000
      maximum: 10000
    excludeVcsIgnoredPaths:
      type: 'boolean'
      default: true
    showNotifications:
      description: 'Show notifications upon clicking task source link.'
      type: 'boolean'
      default: false
    fileOpenerPort:
      type: 'integer'
      default: 9799
    todaysJournal:
      type: 'object'
      properties:
        directory:
          description: 'Where do you want your journal files to live?'
          type: 'string'
          default: "#{path.join(process.env.HOME || process.env.USERPROFILE, 'notes')}"
        fileNameTemplate:
          description: 'How do you want your journal files to be named?'
          type: 'string'
          default: '#{date}.md'
        dateFormat:
          description: 'How would you like your date formatted?'
          type: 'string'
          default: 'YYYY-MM-DD'
    # DONE:40 This is config for globs to open with editors issue:48
    openIn:
      description: 'Open files in a different IDE or editor'
      type: 'object'
      properties:
        intellij:
          type: 'string'
          default: ''
  subscriptions: null

  activate: (state) ->
    # #DONE:180 Add back serialization (The right way) +Roadmap @testing
    atom.deserializers.deserialize(state) if (state)
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

    atom.workspace.addOpener (uriToOpen) =>
      {protocol, host, pathname} = url.parse(uriToOpen)
      return unless protocol is 'imdone:'
      @viewForUri(uriToOpen)

    @fileService = fileService.init atom.config.get('imdone-atom.fileOpenerPort')

    # DONE:210 Add file tree context menu to open imdone issues board. see [Creating Tree View Context-Menu Commands · Issue #428 · atom/tree-view](https://github.com/atom/tree-view/issues/428) due:2015-07-21

  tasks: (projectPath) ->
    previousActivePane = atom.workspace.getActivePane()
    uri = @uriForProject(projectPath)
    return unless uri
    atom.workspace.open(uri, searchAllPanes: true).then (imdoneAtomView) ->
      return unless imdoneAtomView instanceof ImdoneAtomView
      previousActivePane.activate()

  deactivate: ->
    @subscriptions.dispose()

  getCurrentProject: ->
    paths = atom.project.getPaths()
    return unless paths.length > 0
    active = atom.workspace.getActivePaneItem()
    if active && active.getPath && active.getPath()
      # DONE:130 This fails for projects that start with the name of another project
      return projectPath for projectPath in paths when active.getPath().indexOf(projectPath+path.sep) == 0
    else
      paths[0]

  provideService: -> require './plugin-manager'

  openJournalFile: ->
    config = atom.config.get('imdone-atom.todaysJournal')
    dir = config.directory
    dateFormat = config.dateFormat
    file = config.fileNameTemplate.replace '#{date}', moment().format(dateFormat)
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
    imdoneRepo = imdoneHelper.newImdoneRepo(pathname, uri)
    new ImdoneAtomView(imdoneRepo: imdoneRepo, path: pathname, uri: uri)
