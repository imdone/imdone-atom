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


  repo.getProjectId = () -> _.get repo, 'config.sync.id'
  repo.setProjectId = (id) -> _.set repo, 'config.sync.id', id
  repo.getProjectName = () -> _.get repo, 'config.sync.name'
  repo.setProjectName = (name) -> _.set repo, 'config.sync.name', name

  # TODO:0 Handle the case when imdone.io is offline!  Keep a message saying offline! and auto reconnect when it's back. id:44
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
    # READY:0 This should be moved to imdoneio-store id:45
    return if repo.project
    return unless client.isAuthenticated()
    return repo.emit 'project.not-found' unless repo.getProjectId()
    client.getProject repo.getProjectId(), (err, project) =>
      # TODO:0 Do something with this error id:46
      unless project
        repo.disableProject()
        return repo.emit 'project.not-found' unless project
        # Check account for plan type
      return if err
      repo.project = project
      repo.setProjectName project.name
      return unless repo.isImdoneIOProject()
      repo.syncTasks repo.getTasks(), (err, done) =>
        repo.emit 'project.found', project
        done err

  checkForIIOProject() if client.isAuthenticated()
  client.on 'authenticated', => checkForIIOProject()

  syncDone = (err) -> repo.emit 'tasks.updated' unless err
  repo.syncTasks = syncTasks = (tasks, cb) ->
    return cb("unauthenticated", ()->) unless client.isAuthenticated()
    return cb("not enabled") unless repo.getProjectId()
    cm.emit 'tasks.syncing'
    tasks = [tasks] unless _.isArray tasks
    console.log "sending tasks to imdone-io", tasks
    client.syncTasks repo, tasks, (err, ioTasks) ->
      return if err # TODO:0 Do something with this error id:47
      console.log "received tasks from imdone-io:", ioTasks
      async.eachSeries ioTasks,
        # READY:0 We have to be able to match on meta.id for updates. id:48
        # READY:0 Test this with a new project to make sure we get the ids id:49
        # READY:0 We need a way to run tests on imdone-io without destroying the client id:50
        (task, cb) ->
          currentTask = repo.getTask task.id
          taskToModify = _.assign currentTask, task
          return cb "Task not found" unless Task.isTask taskToModify
          repo.modifyTask taskToModify, cb
        (err) ->
          return cm.emit 'sync.error', err if err
          repo.saveModifiedFiles (err, files)->
            # DONE:0 Refresh the board id:51
            return syncDone err unless cb
            cb err, syncDone

  syncFile = (file, cb) ->
    return cb("unauthenticated", ()->) unless client.isAuthenticated()
    return cb("not enabled") unless repo.getProjectId()
    cm.emit 'tasks.syncing'
    console.log "sending tasks to imdone-io for: %s", file.path, file.getTasks()
    client.syncTasks repo, file.getTasks(), (err, tasks) ->
      return if err # TODO:0 Do something with this error id:52
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
    # TODO:0 also get from imdone.io in parallel? or just to start trying id:53

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
    # DONE:0 also save to imdone.io in parallel gh:102 id:54

  saveSortCloud = (cb) ->
    cb ?= ()->
    return cb() unless repo.project
    sort = _.get repo, 'sync.sort'
    repo.project.taskOrder = sort
    # DOING:0 This should call client.updateTaskOrder, but we should also listen for pusher messages on project update id:55
    client.updateProject repo.project, (err, theProject) =>
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
      if shouldSync # DONE:0 Make sure the project is available id:56
        # READY:0 Only sync what we move!!! +important id:57
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
      # READY:0 Try an auth from storage id:58
      client.authFromStorage (err, user) ->
        if sortEnabled()
          _init (err, files) ->
            return cb err if err
            checkForIIOProject()
            populateSort (err) ->
              cb null, files
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

  connectorManager: connectorManager, repo: repo
