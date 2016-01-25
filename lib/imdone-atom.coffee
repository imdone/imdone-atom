ImdoneAtomView        = require './imdone-atom-view'
url                   = require 'url'
{CompositeDisposable} = require 'atom'
path                  = require 'path'
moment                = require 'moment'
mkdirp                = require 'mkdirp'
imdoneHelper          = require './imdone-helper'
fileService           = require './file-service'
{allowUnsafeEval, allowUnsafeNewFunction} = require 'loophole'
_                     = require 'lodash'

module.exports = ImdoneAtom =
  config:
    useAlternateFileWatcher:
      description: "If your board won't update when you edit files, then try the alternate file watcher"
      type: 'boolean'
      default: false
    showTagsInline:
      description: 'Display inline tag and context links in task text?'
      type: 'boolean'
      default: false
    maxFilesPrompt:
      description: 'How many files is too many to parse without prompting to add ignores?'
      type: 'integer'
      default: 2000
      minimum: 1000
      maximum: 10000
    excludeVcsIgnoredPaths:
      description: 'Exclude files that are ignored by your version control system'
      type: 'boolean'
      default: true
    showNotifications:
      description: 'Show notifications upon clicking task source link.'
      type: 'boolean'
      default: false
    fileOpenerPort:
      description: 'Port the file opener communicates on'
      type: 'integer'
      default: 9799
    # DONE:50 This is config for globs to open with editors issue:48
    openIn:
      description: 'Open files in a different IDE or editor'
      type: 'object'
      properties:
        intellij:
          description: '[Glob pattern](https://github.com/isaacs/node-glob) for files that should open in Intellij.'
          type: 'string'
          default: 'Glob pattern'
    todaysJournal:
      type: 'object'
      properties:
        directory:
          description: 'Where do you want your journal files to live? (Their project directory)'
          type: 'string'
          default: "#{path.join(process.env.HOME || process.env.USERPROFILE, 'notes')}"
        fileNameTemplate:
          description: 'How do you want your journal files to be named?'
          type: 'string'
          default: '${date}.md'
        dateFormat:
          description: 'How would you like your `date` variable formatted for use in directory or file name template?'
          type: 'string'
          default: 'YYYY-MM-DD'
        monthFormat:
          description: 'How would you like your `month` variable formatted for use in directory or file name template?'
          type: 'string'
          default: 'YYYY-MM'
  subscriptions: null

  activate: (state) ->
    # #DONE:190 Add back serialization (The right way) +Roadmap @testing
    _.templateSettings.interpolate = /\${([\s\S]+?)}/g;
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

    # DONE:220 Add file tree context menu to open imdone issues board. see [Creating Tree View Context-Menu Commands · Issue #428 · atom/tree-view](https://github.com/atom/tree-view/issues/428) due:2015-07-21

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
      # DONE:140 This fails for projects that start with the name of another project
      return projectPath for projectPath in paths when active.getPath().indexOf(projectPath+path.sep) == 0
    else
      paths[0]

  provideService: -> require './plugin-manager'

  openJournalFile: ->
    allowUnsafeNewFunction ->
      config = atom.config.get('imdone-atom.todaysJournal')
      dateFormat = config.dateFormat
      monthFormat = config.monthFormat
      context =
        date: moment().format(dateFormat)
        month: moment().format(monthFormat)
      file = _.template(config.fileNameTemplate)(context)
      dir = _.template(config.directory)(context)
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
