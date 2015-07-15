ImdoneAtomView = require './imdone-atom-view'
url = require 'url'
{CompositeDisposable} = require 'atom'
_path = require 'path'

module.exports = ImdoneAtom =
  imdoneView: null
  pane: null
  subscriptions: null

  activate: (state) ->
    atom.workspace.addOpener ((uriToOpen) ->
      {protocol, host, pathname} = url.parse(uriToOpen)
      return unless protocol is 'imdone:'
      @viewForUri(uriToOpen)).bind(this)

    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.commands.add 'atom-workspace', "imdone-atom:tasks", => @tasks()

  tasks: ->
    previousActivePane = atom.workspace.getActivePane()
    uri = @uriForProject()
    atom.workspace.open(uri, searchAllPanes: true).done (imdoneAtomView) ->
      return unless imdoneAtomView instanceof ImdoneAtomView
      previousActivePane.activate()

  deactivate: ->
    @subscriptions.dispose()
    @imdoneView.destroy()

  serialize: ->
    imdoneAtomViewState: @imdoneView.serialize()

  getCurrentProject: ->
    paths = atom.project.getPaths()
    return unless paths.length > 0
    active = atom.workspace.getActivePaneItem()
    if active && active.getPath
      return path for path in paths when active.getPath().indexOf(path) == 0
    else
      paths[0]

  uriForProject: ->
    uri = 'imdone://' + _path.basename(@getCurrentProject())

  viewForUri: (uri) ->
    projectPath = @getCurrentProject()
    return unless projectPath
    new ImdoneAtomView(path: projectPath, uri: uri)
