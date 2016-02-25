{$, $$, $$$, View, TextEditorView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
util = require 'util'

module.exports =
class ShareTasksView extends View
  @content: (params) ->
    @div class: "share-tasks-container", =>
      @div outlet:'login-pane', class: 'block imdone-login-pane', =>
        @div class: 'input-med', =>
          @subview 'emailEditor', new TextEditorView(mini: true, placeholderText: 'email')
        @div class: 'input-med', =>
          @subview 'passwordEditor', new TextEditorView(mini: true, placeholderText: 'password')


  initialize: ({@imdoneRepo, @path, @uri}) ->
    @emitter = new Emitter
    @initPasswordField()
    @handleEvents()

  initPasswordField: () ->
    # [Password fields when using EditorView subview - packages - Atom Discussion](https://discuss.atom.io/t/password-fields-when-using-editorview-subview/11061/7)
    passwordElement = $(@passwordEditor.element.rootElement)
    passwordElement.find('div.lines').addClass('password-lines')
    @passwordEditor.getModel().onDidChange =>
      string = @passwordEditor.getModel().getText().split('').map(->
        '*'
      ).join ''

      passwordElement.find('#password-style').remove()
      passwordElement.append('<style id="password-style">.password-lines .line span.text:before {content:"' + string + '";}</style>')

  handleEvents: () ->
