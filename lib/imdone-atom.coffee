ImdoneAtomView = require './imdone-atom-view'
url = require 'url'
{CompositeDisposable} = require 'atom'
_path = require 'path'
ImdoneRepo = require 'imdone-core/lib/repository'
fsStore = require 'imdone-core/lib/mixins/repo-watched-fs-store'

module.exports = ImdoneAtom =
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
        path = projectRoot.getElementsByClassName('name')[0].dataset.path
      @tasks(path)

    atom.workspace.addOpener (uriToOpen) =>
      {protocol, host, pathname} = url.parse(uriToOpen)
      return unless protocol is 'imdone:'
      @viewForUri(uriToOpen)

    # #DONE:20 Add file tree context menu to open imdone issues board. see [Creating Tree View Context-Menu Commands · Issue #428 · atom/tree-view](https://github.com/atom/tree-view/issues/428) due:2015-07-21

  tasks: (path) ->
    previousActivePane = atom.workspace.getActivePane()
    uri = @uriForProject(path)
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
      return path for path in paths when active.getPath().indexOf(path) == 0
    else
      paths[0]

  uriForProject: (path) ->
    projectPath = path || @getCurrentProject()
    projectPath = encodeURIComponent(projectPath)
    'imdone://tasks/' + projectPath

  viewForUri: (uri) ->
    {protocol, host, pathname} = url.parse(uri)
    return unless pathname
    pathname = decodeURIComponent(pathname.split('/')[1])
    new ImdoneAtomView(imdoneRepo: fsStore(new ImdoneRepo(pathname)), path: pathname, uri: uri)
