{$, $$, $$$, View, TextEditorView} = require 'atom-space-pen-views'
async = require 'async'
_ = require 'lodash'

module.exports =
class ConnectorPluginView extends View
  @content: (params)->
    defaultSearch = _.get params, 'connector.defaultSerach' || ''
    @div class:"imdoneio-plugin-view", =>
      @div outlet:'findIssues', class: 'block find-issues', =>
        @div class: 'input-med', =>
          @subview 'findIssuesField', new TextEditorView(mini: true, placeholderText: defaultSearch)
        @div class:'btn-group btn-group-find', =>
          @button click: 'doFind', class:'btn btn-primary inline-block-tight', =>
            @span class:'icon icon-mark-github', 'Find Issues'
          @button click: 'newIssue', class:'btn btn-success inline-block-tight', 'New Issue'
      @div class:'issues-container', =>
        @div outlet: 'searchResult', class: 'issue-list search-result'
        @div outlet: 'relatedIssues', class: 'issue-list related-issues'

  constructor: ({@repo, @imdoneView, @connector}) ->
    super
    @client = require('../services/imdoneio-client').instance
    @handleEvents()

  setTask: (@task) ->

  setConnector: (@connector) ->

  getIssueIds: (task) ->
    @idMetaKey = @connector.config.idMetaKey;
    task = @task unless task
    return null unless task
    metaData = task.getMetaData()
    metaData[@idMetaKey] if (@idMetaKey && metaData)

  handleEvents: ()->
    self = @
    @findIssuesField.on 'keyup', (e) =>
      code = e.keyCode || e.which
      @doFind() if(code == 13)

    @on 'click', '.issue-add', (e) ->
      id = $(@).attr('data-issue-number')
      $(@).closest('li').remove();
      self.task.addMetaData self.idMetaKey, id
      self.repo.modifyTask self.task, true, (err, result) ->
        #console.log err, result
        self.issues = self.getIssueIds()
        self.showRelatedIssues()
        self.imdoneView.emit "task.modified", self.task

    @on 'click', '.issue-remove', (e) ->
      id = $(@).attr('data-issue-number')
      $(@).closest('li').remove();
      self.task.removeMetaData self.idMetaKey, id

      self.repo.modifyTask self.task, true, (err, result) ->
        #console.log err, result
        self.issues = self.getIssueIds()
        self.doFind()
        self.imdoneView.emit "task.modified", self.task

  show: (@issues) ->
    @findIssuesField.focus()
    @showRelatedIssues()
    @doFind()

  showRelatedIssues: () ->
    @relatedIssues.empty()
    return unless @issues
    @relatedIssues.html @$spinner()
    async.map @issues, (number, cb) =>

      @client.getIssue @connector, number, (err, issue) =>
        cb(err, issue)
    , (err, results) =>
      # TODO: Check error for 404/Not Found when getting an issue from provider. +enhancement gh:203 id:1
      # TODO: Be sure to fire waffle rules on the same request as the github issue creation to ensure it starts off in the right waffle list +enhancement gh:204 id:4
      if err
        #console.log "error:", err
      else
        @relatedIssues.html @$issueList(results)

  getSearchQry: ->
    qry = @findIssuesField.getModel().getText()
    return @connector.defaultSearch unless qry
    qry

  doFind: (e) ->
    @searchResult.html @$spinner()
    searchText = @getSearchQry()
    @client.findIssues @connector, searchText, (e, data) =>
      if data
        @searchResult.html @$issueList(data.items, true)
      else
        @searchResult.html 'No issues found'

  newIssue: ->
    # DOING: Also add the task list as a label when creating an issue on github +waffle id:10 gh:242
    @client.newIssue @connector, {title:@task.text}, (e, data) =>
      @task.addMetaData @idMetaKey, data.number
      @repo.modifyTask @task, true, (err, result) =>
        #console.log err, result
        @issues = @getIssueIds()
        @imdoneView.emit "task.modified", @task
        @showRelatedIssues()

  $spinner: ->
    $$ ->
      @div class: 'spinner', =>
        @span class:'loading loading-spinner-large inline-block'

  $issueList: (issues, search) ->
    numbers = @issues
    $$ ->
      @ol =>
        for issue in issues
          unless search && numbers && numbers.indexOf(issue.number.toString()) > -1
            @li class:'issue well', "data-issue-id":issue.id, =>
              @div class:'issue-title', =>
                @p =>
                  @span "#{issue.title} "
                  @a href:issue.html_url, class:'issue-number', "##{issue.number}"
              @div class:'issue-state', =>
                @p =>
                  if issue.state == "open"
                    @span class:'badge badge-success icon icon-issue-opened', 'Open'
                  else
                    @span class:'badge badge-error icon icon-issue-closed', 'Closed'
                  if search
                    @a href:'#', class:'issue-add', "data-issue-number":issue.number, =>
                      @span class:'icon icon-diff-added mega-icon pull-right'
                  else
                    @a href:'#', class:'issue-remove', "data-issue-number":issue.number, =>
                      @span class:'icon icon-diff-removed mega-icon pull-right'
