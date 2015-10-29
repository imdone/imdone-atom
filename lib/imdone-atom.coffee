ImdoneAtomView = require './imdone-atom-view'
url = require 'url'
{CompositeDisposable} = require 'atom'
path = require 'path'
imdoneHelper = require './imdone-helper'

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
  subscriptions: null

  activate: (state) ->
    # #DONE:70 Add back serialization (The right way) +Roadmap @testing
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

    atom.workspace.addOpener (uriToOpen) =>
      {protocol, host, pathname} = url.parse(uriToOpen)
      return unless protocol is 'imdone:'
      @viewForUri(uriToOpen)

    # #DONE:100 Add file tree context menu to open imdone issues board. see [Creating Tree View Context-Menu Commands · Issue #428 · atom/tree-view](https://github.com/atom/tree-view/issues/428) due:2015-07-21

  tasks: (projectPath) ->
    previousActivePane = atom.workspace.getActivePane()
    uri = @uriForProject(projectPath)
    return unless uri
    atom.workspace.open(uri, searchAllPanes: true).done (imdoneAtomView) ->
      return unless imdoneAtomView instanceof ImdoneAtomView
      previousActivePane.activate()

  deactivate: ->
    @subscriptions.dispose()

  getCurrentProject: ->
    paths = atom.project.getPaths()
    return unless paths.length > 0
    active = atom.workspace.getActivePaneItem()
    if active && active.getPath
      # #DONE:30 This fails for projects that start with the name of another project
      return projectPath for projectPath in paths when active.getPath().indexOf(projectPath+path.sep) == 0
    else
      paths[0]

  provideService: -> require './plugin-manager'

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
