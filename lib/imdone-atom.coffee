ImdoneAtomView = require './imdone-atom-view'
ImdoneRepo = require 'imdone-core/lib/repository'
fsStore = require 'imdone-core/lib/mixins/repo-fs-store'
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
      paths = atom.project.getPaths()
      return unless paths.length > 0
      # TODO:0 If more than one path, we need a way to choose
      path = paths[0]
      @loadImdoneRepo(path)
      new ImdoneAtomView(path: paths[0])).bind(this)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', "imdone-atom:tasks", => @tasks('imdone:///')

  tasks: (uri) ->
    previousActivePane = atom.workspace.getActivePane()
    atom.workspace.open(uri).done (imdoneAtomView) ->
      return unless imdoneAtomView instanceof ImdoneAtomView
      previousActivePane.activate()

  loadImdoneRepo: (path) ->
    @imdoneRepos = {} unless @imdoneRepos
    @imdoneRepos[path] = fsStore(new ImdoneRepo(path))

  deactivate: ->
    @subscriptions.dispose()
    @imdoneView.destroy()

  serialize: ->
    imdoneAtomViewState: @imdoneView.serialize()
