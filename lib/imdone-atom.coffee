ImdoneAtomView = require './imdone-atom-view'
url = require 'url'
{CompositeDisposable} = require 'atom'

module.exports = ImdoneAtom =
  imdoneView: null
  pane: null
  subscriptions: null

  activate: (state) ->
    # Register the todolist URI, which will then open our custom view
    atom.workspace.addOpener ((uriToOpen) ->
      {protocol, host, pathname} = url.parse(uriToOpen)
      return unless protocol is 'imdone:'
      projectPath = @getCurrentProject()
      return unless projectPath
      new ImdoneAtomView(path: projectPath)).bind(this)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', "imdone-atom:tasks", => @tasks('imdone:///')

  tasks: (uri) ->
    previousActivePane = atom.workspace.getActivePane()
    atom.workspace.open(uri).done (imdoneAtomView) ->
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
    if active
      return path for path in paths when active.getPath().indexOf(path) == 0
    else
      paths[0]
