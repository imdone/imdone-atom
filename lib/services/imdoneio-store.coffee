module.exports =  (repo) ->
  ConnectorManager = require './connector-manager'
  connectorManager = new ConnectorManager repo
  imdoneioClient = require('./imdoneio-client').instance
  fs = require 'fs'
  async = require 'async'
  path = require 'path'
  CONFIG_DIR = require('imdone-core/lib/constants').CONFIG_DIR
  SORT_FILE = repo.getFullPath path.join(CONFIG_DIR, 'sort.json')

  _getTasksInList = repo.getTasksInList.bind repo
  _getTasksByList = repo.getTasksByList.bind repo
  _init = repo.init.bind repo
  _refresh = repo.refresh.bind repo
  _setTaskPriority = repo.setTaskPriority.bind repo


  loadSortFile = (cb) ->
    fs.exists SORT_FILE, (exists) ->
      return cb() unless exists
      fs.readFile SORT_FILE, (err, data) ->
        return cb err if err
        try
          _.set repo, 'sync.sort', JSON.parse(data.toString());
        catch e
        cb()

  saveSortFile = (cb) ->
    cb ?= ()->
    sort = _.get repo, 'sync.sort'
    fs.writeFile SORT_FILE, JSON.stringify(sort), cb

  isEnabled = () ->
    _ = require 'lodash'
    repo.usingImdoneioForPriority()# && connectorManager.isAuthenticated()

  getTaskId = (task) -> _.get task, 'meta.id[0]'

  tasksToIds = (tasks) -> (getTaskId task for task in tasks)

  getSorts = () -> _.get repo, "sync.sort"

  getListSort = (list) -> _.get getSorts(), list

  getTaskPositionInList = (task, list) -> getListSort(list).indexOf getTaskId task

  setListSort = (obj, save) ->
    setIdsForList obj.name, obj.ids
    repo.saveSortFile() if save

  populateSort = (cb) ->
    fs.exists SORT_FILE, (exists) ->
      return cb() if exists
      # Populate the config.sync.sort from existing sort
      setListSort(name: list.name, ids: tasksToIds(list.tasks)) for list in _getTasksByList()
      saveSortFile cb

  getIdsForList = (name) -> _.get repo, "sync.sort.#{name}"

  setIdsForList = (name, ids) -> _.set repo, "sync.sort.#{name}", ids

  sortBySyncId = (name, tasks) ->
    ids = getIdsForList name
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
    fns = [
      (cb) -> repo.loadConfig cb
      (cb) -> loadSortFile cb
    ]
    async.parallel fns, (err, results) ->
      return cb err if err
      repo.config = results[0]
      return _init cb unless isEnabled()
      _init (err, files) ->
        return cb err if err
        populateSort (err) ->
          cb null, files

  repo.refresh = (cb) ->
    cb ?= ()->
    repo.loadConfig (err, config) ->
      return cb err if err
      repo.config = config
      return _refresh cb unless isEnabled()
      populateSort (err) ->
        _refresh (err, files) ->
          return cb err if err
          cb null, files

  repo.on 'tasks.moved', (tasks) -> saveSortFile()

  connectorManager: connectorManager, repo: repo
