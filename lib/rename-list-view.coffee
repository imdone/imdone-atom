{SpacePenDSL} = require 'atom-utils'

class RenameListView extends HTMLElement
  SpacePenDSL.includeInto(this)

  @content: ->
    @div outlet: 'container', class: 'container', =>
      @span outlet: 'label', class: 'label'

  createdCallback: ->
    # Content is available in the created callback

module.exports = RenameListView = document.registerElement 'imdone-rename-list', prototype: RenameListView.prototype
