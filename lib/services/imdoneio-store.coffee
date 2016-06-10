module.exports =  (repo) ->
  ConnectorManager = require './connector-manager'
  connectorManager = new ConnectorManager repo
  imdoneioClient = require('./imdoneio-client').instance
  async = require 'async'

  _getTasksInList = repo.getTasksInList.bind repo
  _getTasksByList = repo.getTasksByList.bind repo
  _init = repo.init.bind repo
  _moveTasks = repo.moveTasks.bind repo

  isEnabled = () ->
    _ = require 'lodash'
    _.get(repo, 'config.useImdoneioForPriority') && connectorManager.isAuthenticated()

  tasksToIds = (tasks) -> (_.get(task, 'meta.id') for task in tasks)

  getSorts = () -> _.get repo, "config.sync.sort"

  setListSort = (obj, save) ->
    _.set repo, "config.sync.sort.#{obj.name}", obj.tasks
    repo.saveConfig() if save

  populateSort = () ->
    # Populate the config.sync.sort from existing sort
    setListSort(name: list, tasks: tasksToIds(tasks)) for list, tasks of _getTasksByList()
    repo.saveConfig()

  addSyncSortToTasks = (tasks) ->
    task.sync_sort = index for task, index in tasks

  applySortsToTasks = () ->
    populateSort() unless getSorts()
    # Now set the synced_sort on each task
    sorts = getSorts()
    addSyncSortToTasks tasks for list, tasks of _getTasksByList()

  updateSortStore = (tasksByList, cb) ->
    async.eachSeries tasksByList,
      (hash, cb) ->
        arrayOfIds  = (_.get(task,'meta.id[0]') for task in hash.tasks)
        sort = name: hash.list, tasks:arrayOfIds
        setListSort sort
        cb()
      (err) ->
        repo.saveConfig() unless err
        cb err, tasksByList

  repo.getTasksInList = (name, offset, limit) ->
    tasksInList = _getTasksInList  name, offset, limit
    return tasksInList unless isEnabled()
    # DOING: Change sort order to db driven/imdone.io sort
    sorts = _.get repo, "imdoneio.sorts.#{name}"
    # DOING: Add the imdoneio_sort to the tasks, then sort
    tasksInList

  repo.getTasksByList = () ->
    tasksByList = _getTasksByList()
    return tasksByList unless isEnabled()
    # DOING: Change sort order to db driven/imdone.io sort
    sorts = _.get repo, 'imdoneio.sorts'
    # DOING: Add the imdoneio_sort to the tasks, then sort
    tasksByList

  repo.init = (cb) ->
    cb ?= ()->
    repo.loadConfig (err) ->
      debugger
      return cb err if err
      return _init cb unless repo.config.useImdoneioForPriority
      applySortsToTasks()
      _init cb

  repo.moveTasks = (tasks, newList, newPos, cb) ->
    cb ?= ()->
    _moveTasks tasks, newList, newPos,
      (err, tasksByList) ->
        return updateSortStore tasksByList, cb if isEnabled()
        cb err, tasksByList

  connectorManager: connectorManager, repo: repo
