module.exports =  (repo) ->
  ConnectorManager = require './connector-manager'
  connectorManager = new ConnectorManager repo
  imdoneioClient = require('./imdoneio-client').instance
  async = require 'async'

  _getTasksInList = repo.getTasksInList.bind repo
  _getTasksByList = repo.getTasksByList.bind repo
  _init = repo.init.bind repo
  _refresh = repo.refresh.bind repo
  _setTaskPriority = repo.setTaskPriority.bind repo

  isEnabled = () ->
    _ = require 'lodash'
    repo.usingImdoneioForPriority()# && connectorManager.isAuthenticated()

  getTaskId = (task) -> _.get task, 'meta.id[0]'

  tasksToIds = (tasks) -> (getTaskId task for task in tasks)

  getSorts = () -> _.get repo, "config.sync.sort"

  getListSort = (list) -> _.get getSorts(), list

  getTaskPositionInList = (task, list) -> getListSort(list).indexOf getTaskId task

  setListSort = (obj, save) ->
    setIdsForList obj.name, obj.ids
    repo.saveConfig() if save

  populateSort = () ->
    return if getSorts()
    # Populate the config.sync.sort from existing sort
    setListSort(name: list.name, ids: tasksToIds(list.tasks)) for list in _getTasksByList()
    repo.saveConfig()

  updateSortStore = (tasksByList, cb) ->
    async.eachSeries tasksByList,
      (hash, cb) ->
        arrayOfIds  = tasksToIds hash.tasks
        setListSort name: hash.list, tasks:arrayOfIds
        cb()
      (err) ->
        repo.saveConfig() unless err
        cb err, tasksByList

  idsForList = (name) -> _.get repo, "config.sync.sort.#{name}"

  setIdsForList = (name, ids) -> _.set repo, "config.sync.sort.#{name}", ids

  sortBySyncId = (name, tasks) ->
    ids = idsForList name
    return tasks unless ids
    _.sortBy tasks, (task) -> ids.indexOf getTaskId task

  repo.setTaskPriority = (task, index, cb) ->
    return _setTaskPriority task, index, cb unless isEnabled()

    if task.oldList
      getListSort(task.oldList).splice getTaskPositionInList(task, task.oldList), 1
    else
      getListSort(task.list).splice getTaskPositionInList(task, task.list), 1

    getListSort(task.list).splice index, 0, getTaskId(task)

    cb()

  repo.getTasksInList = (name, offset, limit) ->
    tasksInList = _getTasksInList  name, offset, limit
    return tasksInList unless isEnabled()
    sortBySyncId name, tasksInList

  repo.getTasksByList = () ->
    tasksByList = _getTasksByList()
    return tasksByList unless isEnabled()
    (sortBySyncId list.name, list.tasks for list in tasksByList)

  repo.init = (cb) ->
    cb ?= ()->
    repo.loadConfig (err) ->
      return cb err if err
      return _init cb unless isEnabled()
      _init (err, files) ->
        return cb err if err
        populateSort()
        cb null, files

  repo.refresh = (cb) ->
    cb ?= ()->
    repo.loadConfig (err, config) ->
      return cb err if err
      repo.config = config
      return _refresh cb unless isEnabled()
      populateSort()
      _refresh (err, files) ->
        return cb err if err
        cb null, files

  repo.on 'tasks.moved', (tasks) -> repo.saveConfig()

  connectorManager: connectorManager, repo: repo
