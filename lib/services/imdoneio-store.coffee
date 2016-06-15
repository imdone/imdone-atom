module.exports =  (repo) ->
  ConnectorManager = require './connector-manager'
  connectorManager = new ConnectorManager repo
  imdoneioClient = require('./imdoneio-client').instance
  fs = require 'fs'
  _ = require 'lodash'
  async = require 'async'
  path = require 'path'
  CONFIG_DIR = require('imdone-core/lib/constants').CONFIG_DIR
  SORT_FILE = repo.getFullPath path.join(CONFIG_DIR, 'sort.json')

  _getTasksInList = repo.getTasksInList.bind repo
  _getTasksByList = repo.getTasksByList.bind repo
  _init = repo.init.bind repo
  _refresh = repo.refresh.bind repo
  _setTaskPriority = repo.setTaskPriority.bind repo
  _moveTasks = repo.moveTasks.bind repo


  loadSort = (cb) ->
    loadSortFile cb
    # TODO: also get from imdone.io in parallel? or just to start trying id:0

  loadSortFile = (cb) ->
    fs.exists SORT_FILE, (exists) ->
      return cb() unless exists
      fs.readFile SORT_FILE, (err, data) ->
        return cb err if err
        try
          _.set repo, 'sync.sort', JSON.parse(data.toString());
        catch e
        cb()

  saveSort = (cb) ->
    saveSortFile cb
    # DOING: also save to imdone.io in parallel id:1

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

  setListSort = (name, ids, save) ->
    _.set repo, "sync.sort.#{name}", ids
    saveSort() if save

  populateSort = (cb) ->
    fs.exists SORT_FILE, (exists) ->
      return cb() if exists
      # Populate the config.sync.sort from existing sort
      setListSort list.name, tasksToIds(list.tasks) for list in _getTasksByList()
      saveSort cb

  getIdsForList = (name) -> _.get repo, "sync.sort.#{name}"

  sortBySyncId = (name, tasks) ->
    ids = getIdsForList name
    return tasks unless ids
    _.sortBy tasks, (task) -> ids.indexOf getTaskId task

  repo.setTaskPriority = (task, pos, cb) ->
    taskId = getTaskId task
    list = task.list
    idsWithoutTask = _.without getIdsForList(list), getTaskId task
    idsWithoutTask.splice pos, 0, taskId
    setListSort list, idsWithoutTask
    cb()

  repo.moveTasks = (tasks, newList, newPos, cb) ->
    cb ?= ()->
    _moveTasks tasks, newList, newPos, (err, tasksByList) ->
      return cb err if err
      return cb null, tasksByList unless isEnabled()
      saveSort (err) -> cb err, tasksByList

  repo.getTasksInList = (name, offset, limit) ->
    tasksInList = _getTasksInList  name, offset, limit
    return tasksInList unless isEnabled()
    sortBySyncId name, tasksInList

  repo.getTasksByList = () ->
    tasksByList = _getTasksByList()
    return tasksByList unless isEnabled()
    ({name: list.name, tasks: sortBySyncId(list.name, list.tasks)} for list in tasksByList)

  repo.init = (cb) ->
    cb ?= ()->
    fns = [
      (cb) -> repo.loadConfig cb
      (cb) -> loadSort cb
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

  connectorManager: connectorManager, repo: repo
