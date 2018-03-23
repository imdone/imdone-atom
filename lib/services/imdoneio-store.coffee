{$} = require 'atom-space-pen-views'

module.exports =  (repo) ->
  CONFIG_DIR = require('imdone-core/lib/constants').CONFIG_DIR
  ERRORS = require('imdone-core/lib/constants').ERRORS
  ConnectorManager = require './connector-manager'
  connectorManager = cm = new ConnectorManager repo
  Client = require('./imdoneio-client')
  imdoneioClient = client = Client.instance
  log = require('debug') 'imdoneio-store'
  transform = require('./transform')
  Task = require 'imdone-core/lib/task'
  Reminders = require './reminders'
  waitUntil = require 'wait-until'
  fs = require 'fs'
  _ = require 'lodash'
  async = require 'async'
  path = require 'path'
  SORT_FILE = repo.getFullPath path.join(CONFIG_DIR, 'sort.json')

  _getTasksInList = repo.getTasksInList.bind repo
  _getTasksByList = repo.getTasksByList.bind repo
  _init = repo.init.bind repo
  _refresh = repo.refresh.bind repo
  _setTaskPriority = repo.setTaskPriority.bind repo
  _moveTasks = repo.moveTasks.bind repo
  _emitFileUpdate = repo.emitFileUpdate.bind repo

  plugins = []

  client.on 'authenticated', -> repo.emit 'authenticated'
  client.on 'unauthenticated', -> repo.emit 'unauthenticated'
  client.on 'authentication-failed', ({status, retries}) -> repo.emit 'authentication-failed', ({status, retries})
  client.on 'unavailable', -> repo.emit 'unavailable'

  repo.getProjectId = () -> _.get repo, 'config.sync.id'
  repo.setProjectId = (id) -> _.set repo, 'config.sync.id', id
  repo.getProjectName = () -> _.get repo, 'config.sync.name'
  repo.setProjectName = (name) -> _.set repo, 'config.sync.name', name

  # TODO: Handle the case when imdone.io is offline! Keep a message saying offline! and auto reconnect when it's back. gh:239 id:95
  repo.isImdoneIOProject = () -> client.isAuthenticated() && repo.project && !repo.project.disabled

  repo.disableProject = (cb) ->
    cb ?= ()->
    projectId = repo.getProjectId()
    delete repo.config.sync
    delete repo.project
    repo.saveConfig (err) =>
      return cb err if err
      tasks = repo.getTasks()
      async.eachSeries tasks,
        (task, cb) ->
          currentTask = repo.getTask task.id
          taskToModify = _.assign currentTask, task
          return cb "Task not found" unless Task.isTask taskToModify
          delete taskToModify.meta.id
          repo.modifyTask taskToModify, cb
        (err) ->
          repo.saveModifiedFiles (err, files) ->
            return cb err if err
            repo.emit 'tasks.updated', tasks
            repo.emit 'project.removed'
            cb()

  repo.checkForIIOProject = checkForIIOProject = () ->
    log "Checking for imdone.io project"

    return repo.emit('project.found', repo.project) if repo.project
    return unless client.isAuthenticated() && repo.initialized
    return repo.emit 'project.not-found' unless repo.getProjectId()
    client.getProject repo.getProjectId(), (err, project) =>
      # TODO: Do something with this error gh:116 id:87
      unless project
        # repo.disableProject()
        return repo.emit 'project.not-found' unless project # TODO: Handle the case where there is no project found. gh:116 id:72
        # Check account for plan type
      return throw err if err
      repo.project = project
      repo.setProjectName project.name
      return unless repo.isImdoneIOProject()
      _.set repo, 'sync.sort', project.taskOrder if sortEnabled()
      repo.emit 'project.found', project
      repo.initProducts()

  checkForIIOProject() if client.isAuthenticated()
  repo.on 'authenticated', => checkForIIOProject()
  # repo.on 'initialized', => checkForIIOProject()

  repo.transformTasks = (tasks, cb) =>
    return cb(null, repo.getTasks()) unless client.isAuthenticated()
    return cb(null, repo.getTasks()) if !client.plan || client.plan.free
    waitUntil 200, 10, () =>
      !repo.savingFiles
    , (result) =>
      return cb(null, repo.getTasks()) unless result
      repo.pause()
      transformed = transform.transformTasks repo.config, tasks
      async.mapSeries transformed, (task, cb) =>
        repo.modifyTask task, false, (err, updatedTask) =>
          return cb(null, updatedTask) unless err
          cb err
      , (err, results) ->
        if err
          repo.resume()
          return cb err
        repo.saveModifiedFiles (err) =>
          repo.resume()
          repo.reminders.schedule()
          return cb err if err
          cb(null, repo.getTasks())

  syncDone = (tasks) ->
    return (err) ->
      repo.emit 'tasks.updated', tasks unless err
      return if err == ERRORS.NO_CONTENT
      throw err if err

  loadSort = (cb) ->
    loadSortFile cb

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
    cb ?= () ->
    fns = [
      (cb) -> saveSortFile cb
      (cb) -> saveSortCloud cb
    ]
    async.parallel fns, cb


  saveSortCloud = (cb) ->
    cb ?= ()->
    return cb() unless repo.project
    sort = _.get repo, 'sync.sort'

    client.updateTaskOrder repo.project.id, sort, (err, theProject) =>
      return cb(err) if err
      cb null, theProject.taskOrder

  saveSortFile = (cb) ->
    cb ?= ()->
    sort = _.get repo, 'sync.sort'
    fs.writeFile SORT_FILE, JSON.stringify(sort), cb

  sortEnabled = () -> repo.usingImdoneioForPriority()

  getTaskId = (task) ->
    id = _.get task, 'meta.id[0]'
    return id if id
    task.id

  tasksToIds = (tasks) -> (getTaskId task for task in tasks)

  getSorts = () -> _.get repo, "sync.sort"

  getListSort = (list) -> _.get getSorts(), list

  setListSort = (name, ids, save) ->
    _.remove ids, (val) -> val == null
    _.set repo, "sync.sort.#{name}", ids
    saveSort() if save

  populateSort = (cb) ->
    return saveSort(cb) if _.get repo, 'project.taskOrder'
    fs.exists SORT_FILE, (exists) ->
      return cb() if exists
      # BACKLOG: remove sort number on all TODO comments when saving sort to cloud +enhancement gh:168 id:88
      # Populate the config.sync.sort from existing sort
      setListSort list.name, tasksToIds(list.tasks) for list in _getTasksByList()
      saveSort cb

  getIdsForList = (name) -> _.get repo, "sync.sort.#{name}"

  sortBySyncId = (name, tasks) ->
    ids = getIdsForList name
    return tasks unless ids
    _.sortBy tasks, (task) -> ids.indexOf getTaskId task

  repo.setTaskPriority = (task, pos, cb) ->
    return _setTaskPriority task, pos, cb unless sortEnabled()
    taskId = getTaskId task
    list = task.list
    idsWithoutTask = _.without getIdsForList(list), getTaskId task
    idsWithoutTask.splice pos, 0, taskId
    setListSort list, idsWithoutTask
    cb()

  repo.moveTasks = (tasks, newList, newPos, cb) ->
    shouldSync  = repo.isImdoneIOProject()
    cb ?= ()->
    _moveTasks tasks, newList, newPos, shouldSync, (err, tasksByList) ->
      repo.emit 'tasks.moved', tasks
      return cb err if err
      return cb null, tasksByList unless sortEnabled()
      saveSort (err) -> cb err, tasksByList

  repo.getTasksInList = (name, offset, limit) ->
    tasksInList = _getTasksInList  name, offset, limit
    return tasksInList unless sortEnabled()
    sortBySyncId name, tasksInList

  repo.getTasksByList = () ->
    tasksByList = _getTasksByList()
    return tasksByList unless sortEnabled()
    ({name: list.name, tasks: sortBySyncId(list.name, list.tasks)} for list in tasksByList)

  repo.init = (cb) ->
    cb ?= ()->
    fns = [
      (cb) -> repo.loadConfig cb
      (cb) -> loadSort cb
    ]
    async.parallel fns, (err, results) ->
      console.log "loaded config", repo.config
      return cb err if err
      repo.config = results[0]

      client.authFromStorage (err, user) ->
        if sortEnabled()
          _init (err, files) ->
            return cb err if err
            repo.reminders = new Reminders(repo);
            checkForIIOProject()
            populateSort (err) -> cb null, files
        else
          _init (err, files) ->
            repo.reminders = new Reminders(repo);
            return cb err if err
            checkForIIOProject()
            cb null, files
  repo.refresh = (cb) ->
    cb ?= ()->
    repo.loadConfig (err, config) ->
      return cb err if err
      repo.config = config
      return _refresh cb unless sortEnabled()
      populateSort (err) ->
        _refresh (err, files) ->
          return cb err if err
          cb null, files

  # BACKLOG: Provide a way to delete tasks after they integrate, maybe a delete\:true on the returning task. gh:244 id:73
  repo.initProducts = (cb) ->
    cb ?= ()->
    connectorManager.getProducts (err, products) =>
      return cb(err) if err
      repo.emit 'connector.enabled', product.connector for product in products when product.isEnabled()
      cb()

  repo.addPlugin = (plugin) ->
    repo.removePlugin plugin
    @plugins.push plugin

  repo.removePlugin = (plugin) ->
    return unless plugin
    @plugins = _.reject plugins, { pluginName: plugin.pluginName }

  repo.getPlugins = () -> @plugins

  repo.visibleTasks = (list) ->
    visibleTasks = []
    addTask = (id) =>
      visibleTasks.push repo.getTask(id)
    return visibleTasks unless repo.$board
    repo.$board.find('.task').each ->
      return unless !list || $(this).closest('.tasks').data('list') == list
      return if $(this).is ':hidden'
      addTask $(this).attr('id')

    visibleTasks

  repo.deleteVisibleTasks = (cb) -> repo.deleteTasks repo.visibleTasks(), cb

  connectorManager.on 'tasks.syncing', () -> repo.emit 'tasks.syncing'
  connectorManager.on 'sync.error', () -> repo.emit 'sync.error'
  connectorManager.on 'product.linked', (product) -> repo.emit 'product.linked', product
  connectorManager.on 'product.unlinked', (product) -> repo.emit 'product.unlinked', product
  repo.getProduct = (provider, cb) -> connectorManager.getProduct provider, cb
  repo.getProducts = (cb) -> connectorManager.getProducts(cb)
  repo.saveConnector = (connector, cb) -> connectorManager.saveConnector connector, cb
  repo.enableConnector = (connector, cb) -> connectorManager.enableConnector connector, cb
  repo.disableConnector = (connector, cb) -> connectorManager.disableConnector connector, cb
  repo.getGitOrigin = () -> connectorManager.getGitOrigin()
  repo.githubAuthUrl = Client.githubAuthUrl
  repo.authenticate = client.authenticate.bind client
  repo.isAuthenticated = client.isAuthenticated.bind client
  repo.authFromStorage = client.authFromStorage.bind client
  repo.logoff = client.logoff.bind client
  repo.user = () -> client.user
  repo.plansUrl = Client.plansUrl
  repo.projectsUrl = Client.projectsUrl
  repo.connectorManager = connectorManager
  repo
