module.exports =  (repo) ->
  ConnectorManager = require './connector-manager'
  connectorManager = cm = new ConnectorManager repo
  imdoneioClient = client = require('./imdoneio-client').instance
  Task = require 'imdone-core/lib/task'
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
  _emitFileUpdate = repo.emitFileUpdate.bind repo

  client.on 'authenticated', -> repo.emit 'authenticated'
  client.on 'unauthenticated', -> repo.emit 'unauthenticated'
  client.on 'authentication-failed', ({status, retries}) -> repo.emit 'authentication-failed', ({status, retries})
  client.on 'unavailable', -> repo.emit 'unavailable'

  repo.getProjectId = () -> _.get repo, 'config.sync.id'
  repo.setProjectId = (id) -> _.set repo, 'config.sync.id', id
  repo.getProjectName = () -> _.get repo, 'config.sync.name'
  repo.setProjectName = (name) -> _.set repo, 'config.sync.name', name

  # TODO:0 Handle the case when imdone.io is offline!  Keep a message saying offline! and auto reconnect when it's back. id:39
  repo.isImdoneIOProject = () -> client.isAuthenticated() && repo.project && !repo.project.disabled

  repo.disableProject = (cb) ->
    cb ?= ()->
    projectId = repo.getProjectId()
    delete repo.config.sync
    delete repo.project
    repo.saveConfig (err) =>
      return cb err if err
      async.eachSeries repo.getTasks(),
        (task, cb) ->
          currentTask = repo.getTask task.id
          taskToModify = _.assign currentTask, task
          return cb "Task not found" unless Task.isTask taskToModify
          delete taskToModify.meta.id
          repo.modifyTask taskToModify, cb
        (err) ->
          repo.saveModifiedFiles (err, files) ->
            return cb err if err
            repo.emit 'tasks.updated'
            repo.emit 'project.removed'
            cb()

  repo.checkForIIOProject = checkForIIOProject = () ->
    console.log "Checking for imdone.io project"
    # READY:0 This should be moved to imdoneio-store id:40
    return repo.emit('project.found', repo.project) if repo.project
    return unless client.isAuthenticated() && repo.initialized
    return repo.emit 'project.not-found' unless repo.getProjectId()
    client.getProject repo.getProjectId(), (err, project) =>
      # TODO:0 Do something with this error id:41
      unless project
        repo.disableProject()
        return repo.emit 'project.not-found' unless project
        # Check account for plan type
      return if err
      repo.project = project
      repo.setProjectName project.name
      return unless repo.isImdoneIOProject()
      _.set repo, 'sync.sort', project.taskOrder if sortEnabled()
      repo.syncTasks repo.getTasks(), (err, done) =>
        repo.emit 'project.found', project
        repo.initProducts()
        done err if done

  checkForIIOProject() if client.isAuthenticated()
  client.on 'authenticated', => checkForIIOProject()

  syncDone = (err) -> repo.emit 'tasks.updated' unless err

  repo.syncTasks = syncTasks = (tasks, cb) ->
    return cb("unauthenticated", ()->) unless client.isAuthenticated()
    return cb("not enabled") unless repo.getProjectId()
    tasks = [tasks] unless _.isArray tasks
    return cb() unless tasks.length > 0
    # DONE: Keep sync from happening twice +bug +beta gh:140 id:42
    cm.emit 'tasks.syncing'
    console.log "sending tasks to imdone-io", tasks
    client.syncTasks repo, tasks, (err, ioTasks) ->
      return if err # TODO:0 Do something with this error id:43
      console.log "received tasks from imdone-io:", ioTasks
      async.eachSeries ioTasks,
        # READY:0 We have to be able to match on meta.id for updates. id:44
        # READY:0 Test this with a new project to make sure we get the ids id:45
        # READY:0 We need a way to run tests on imdone-io without destroying the client id:46
        (task, cb) ->
          currentTask = repo.getTask task.id
          taskToModify = _.assign currentTask, task
          return cb "Task not found" unless Task.isTask taskToModify
          repo.modifyTask taskToModify, cb
        (err) ->
          if err
            console.log "Sync Error:", err
            return cm.emit 'sync.error', err
          repo.saveModifiedFiles (err, files)->
            # DONE: Refresh the board id:47
            return syncDone err unless cb
            cb err, syncDone

  syncFile = (file, cb) ->
    return cb("unauthenticated", ()->) unless client.isAuthenticated()
    return cb("not enabled") unless repo.getProjectId()
    cm.emit 'tasks.syncing'
    console.log "sending tasks to imdone-io for: %s", file.path, file.getTasks()
    client.syncTasks repo, file.getTasks(), (err, tasks) ->
      return if err # TODO:0 Do something with this error id:48
      console.log "received tasks from imdone-io for: %s", tasks
      async.eachSeries tasks,
        (task, cb) ->
          taskToModify = _.assign repo.getTask(task.id), task
          return cb "Task not found" unless Task.isTask taskToModify
          repo.modifyTask taskToModify, cb
        (err) ->
          return cm.emit 'sync.error', err if err
          repo.writeFile file, (err, file)->
            return syncDone err unless cb
            cb err, syncDone

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
    # DONE: also save to imdone.io in parallel gh:102 id:49

  saveSortCloud = (cb) ->
    cb ?= ()->
    return cb() unless repo.project
    sort = _.get repo, 'sync.sort'
    # READY:0 This should call client.updateTaskOrder, but we should also listen for pusher messages on project update id:50
    client.updateTaskOrder repo.project.id, sort, (err, theProject) =>
      return cb(err) if err
      cb null, theProject.taskOrder

  saveSortFile = (cb) ->
    cb ?= ()->
    sort = _.get repo, 'sync.sort'
    fs.writeFile SORT_FILE, JSON.stringify(sort), cb

  sortEnabled = () -> repo.usingImdoneioForPriority()

  getTaskId = (task) -> _.get task, 'meta.id[0]'

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
      return cb err if err
      if shouldSync # DONE: Make sure the project is available id:51
        # READY:0 Only sync what we move!!! +important id:52
        console.log "Tasks moved.  Syncing with imdone.io"
        syncTasks tasks, (err, done) ->
          repo.emit 'tasks.moved', tasks
          return cb null, tasksByList unless sortEnabled()
          saveSort (err) ->
            done err
            cb err, tasksByList
      else
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

  repo.emitFileUpdate = (file) ->
    return _emitFileUpdate file unless client.isAuthenticated() && repo.project
    if repo.shouldEmitFileUpdate file
      syncFile file, (err, done) ->
        _emitFileUpdate file
        done err


  repo.init = (cb) ->
    cb ?= ()->
    fns = [
      (cb) -> repo.loadConfig cb
      (cb) -> loadSort cb
    ]
    async.parallel fns, (err, results) ->
      return cb err if err
      repo.config = results[0]
      # READY:0 Try an auth from storage id:53
      client.authFromStorage (err, user) ->
        if sortEnabled()
          _init (err, files) ->
            return cb err if err
            checkForIIOProject()
            populateSort (err) -> cb null, files
        else
          _init (err, files) ->
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

  repo.initProducts = () ->
    connectorManager.getProducts (err, products) =>
      return if err
      repo.emit 'connector.enabled', product.connector for product in products when product.isEnabled()

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

  repo.connectorManager = connectorManager
  repo
