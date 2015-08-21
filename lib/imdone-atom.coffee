ImdoneAtomView = require './imdone-atom-view'
url = require 'url'
{CompositeDisposable} = require 'atom'
path = require 'path'
ImdoneRepo = require 'imdone-core/lib/repository'
fsStore = require 'imdone-core/lib/mixins/repo-watched-fs-store'

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

  imdoneView: null
  pane: null
  subscriptions: null

  activate: (state) ->
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

    # #DONE:50 Add file tree context menu to open imdone issues board. see [Creating Tree View Context-Menu Commands · Issue #428 · atom/tree-view](https://github.com/atom/tree-view/issues/428) due:2015-07-21

  tasks: (projectPath) ->
    previousActivePane = atom.workspace.getActivePane()
    uri = @uriForProject(projectPath)
    return unless uri
    atom.workspace.open(uri, searchAllPanes: true).done (imdoneAtomView) ->
      return unless imdoneAtomView instanceof ImdoneAtomView
      previousActivePane.activate()

  deactivate: ->
    @subscriptions.dispose()
    @imdoneView.destroy()

  # #BACKLOG:0 Add back serialization (The right way)
  # serialize: ->
  #   imdoneAtomViewState: @imdoneView.serialize()

  getCurrentProject: ->
    paths = atom.project.getPaths()
    return unless paths.length > 0
    active = atom.workspace.getActivePaneItem()
    if active && active.getPath
      return projectPath for projectPath in paths when active.getPath().indexOf(projectPath) == 0
    else
      paths[0]

  uriForProject: (projectPath) ->
    projectPath = projectPath || @getCurrentProject()
    return unless projectPath
    projectPath = encodeURIComponent(projectPath)
    'imdone://tasks/' + projectPath

  viewForUri: (uri) ->
    {protocol, host, pathname} = url.parse(uri)
    return unless pathname
    pathname = decodeURIComponent(pathname.split('/')[1])
    imdoneRepo = fsStore(new ImdoneRepo(pathname))
    @excludeVcsIgnoresMixin(imdoneRepo)
    new ImdoneAtomView(imdoneRepo: imdoneRepo, path: pathname, uri: uri)

  excludeVcsIgnoresMixin: (imdoneRepo) ->
    keyPath = 'imdone-atom.excludeVcsIgnoredPaths'
    repoPath = imdoneRepo.getPath()
    vcsRepo = @repoForPath repoPath
    _shouldExclude = imdoneRepo.shouldExclude
    shouldExclude = (relPath) ->
      return true if vcsRepo.isPathIgnored(relPath)
      _shouldExclude.call imdoneRepo, relPath

    imdoneRepo.shouldExclude = shouldExclude if atom.config.get(keyPath)
    atom.config.observe keyPath, (exclude) ->
      imdoneRepo.shouldExclude = if exclude then shouldExclude else _shouldExclude
      imdoneRepo.refresh() if imdoneRepo.initialized

  repoForPath: (repoPath) ->
    for projectPath, i in atom.project.getPaths()
      if repoPath is projectPath or repoPath.indexOf(projectPath + path.sep) is 0
        return atom.project.getRepositories()[i]
    null
