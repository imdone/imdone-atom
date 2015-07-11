{$, $$$, ScrollView} = require 'atom-space-pen-views'
{Emitter, Disposable, CompositeDisposable} = require 'atom'
path = require 'path'

module.exports =
class ImdoneAtomView extends ScrollView
  @content: (params) ->
    @div class: "imdone-atom", =>
      @div class: "imdone-loading", =>
        @h4 "Loading #{path.basename(params.path)} Issues"

  getTitle: ->
    "#{path.basename(@path)} Issues"

  constructor: ({@path}) ->
    super
