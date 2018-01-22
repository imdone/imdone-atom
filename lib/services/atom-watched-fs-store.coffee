fs          = require 'fs-plus'
fsStore     = require 'imdone-core/lib/mixins/repo-fs-store'
File        = require 'imdone-core/lib/file'
constants   = require 'imdone-core/lib/constants'
sep         = require('path').sep
log         = require './log'
async       = require 'async'
{CompositeDisposable} = require 'atom'


class HashCompositeDisposable extends CompositeDisposable
  constructor: (@repo)->
    @watched = {}
    super()

  add: (path, disposable) ->
    @watched[path] = {disposables:[]} unless @watched[path]
    @remove disposable
    @watched[path].disposables.push disposable
    super disposable

  remove: (path) ->
    return super(path) unless typeof path is 'string'
    return unless @watched[path] && @watched[path].disposables
    log "disposable removed for #{path}"
    super(disposable) for disposable in @watched[path].disposables
    delete @watched[path]

  removeDir: (dir) ->
    @remove dir
    dir += sep
    @remove path for path, watched of @watched when path.indexOf(dir) == 0

  removeDeletedChildren: (dir) ->
    dir += sep
    for path, watched of @watched when path.indexOf(dir) == 0
      @remove path unless fs.existsSync path

  get: (path) ->
    return @watched[path]

  dispose: ->
    @watched = {}
    super()

class Watcher
  constructor: (@repo)->
    dir = (dir for dir in atom.project.getDirectories() when dir.getPath() is @repo.path)[0]
    @watched = new HashCompositeDisposable(@repo)
    @files = {}
    @watchDir dir

  close: ->
    @closeWatcher path for path, watcher of @watched.watched
    @watched.dispose()

  closeWatcher: (path) ->
    log "Stopped watching #{path}"
    @watched.remove path

  pause: ->
    @paused = true

  resume: ->
    @paused = false

  pathOrEntry: (pathOrEntry) ->
    if typeof pathOrEntry is 'string' then pathOrEntry else pathOrEntry.getPath()

  shouldExclude: (pathOrEntry) ->
    path = @pathOrEntry(pathOrEntry)
    relPath = @repo.getRelativePath(path);
    return false if (relPath.indexOf('.imdone') == 0)
    @repo.shouldExclude(relPath);

  isImdoneConfig: (pathOrEntry) ->
    path = @pathOrEntry(pathOrEntry)
    relPath = @repo.getRelativePath path
    relPath.indexOf(constants.CONFIG_FILE) > -1

  isImdoneIgnore: (pathOrEntry) ->
    path = @pathOrEntry(pathOrEntry)
    relPath = @repo.getRelativePath path
    relPath.indexOf(constants.IGNORE_FILE) > -1

  getWatcher: (pathOrEntry) ->
    return unless pathOrEntry && @watched
    path = @pathOrEntry(pathOrEntry)
    @watched.get path

  setFileStats: (entry, cb) ->
    _path = entry.getPath()
    watched = @files[_path]
    watched = @files[_path] = {} unless watched
    fs.stat _path, (err, stats) ->
      return log err if err
      watched.mtime  = stats.mtime
      cb() if cb

  getFileStats: (pathOrEntry) ->
    path = @pathOrEntry(pathOrEntry)
    @files[path]

  removeFile: (path) ->
    delete @files[path]

  isReallyChanged: (entry, cb) ->
    return false if @shouldExclude(entry)
    path = entry.getPath()
    log "Checking if #{entry.getPath()} is really changed"
    fs.list entry.getParent().getPath(), (err, paths) =>
      return cb(err) if err?
      return cb(null, true) unless paths && paths.indexOf(path) > -1
      watcher = @getFileStats entry
      return cb(null, true) unless watcher
      fs.stat path, (err, stat) ->
        return cb err if err
        return cb(null, false) unless stat && stat.mtime
        return cb(null, false) if watcher.mtime.getTime() == stat.mtime.getTime()
        watcher.mtime = stat.mtime
        # digest = file.getDigestSync()
        # return false unless digest != watcher.digest
        # watcher.digest = digest
        cb null, true

  isNewEntry: (pathOrEntry) ->
    return true unless @shouldExclude(pathOrEntry) || @fileInRepo(pathOrEntry) || @isImdoneConfig(pathOrEntry) || @isImdoneIgnore(pathOrEntry) || @getWatcher pathOrEntry

  hasNewChildren: (entry, cb) ->
    fs.list entry.getPath(), (err, paths) =>
      return cb(err) if error?
      for path in paths
        return cb(null, true) if @isNewEntry path
      return cb(null, false)

  fileInRepo: (pathOrEntry) ->
    path = @pathOrEntry(pathOrEntry)
    relPath = @repo.getRelativePath path
    @repo.getFile(relPath)

  watchDir: (dir) ->
    @watchPath dir
    dir.getEntries (err, entries) =>
      for entry in entries
        if entry.isDirectory()
          @watchDir entry if !@shouldExclude(entry)
        else if entry.isFile()
          @watchFile entry if !@shouldExclude(entry)

  watchFile: (entry) ->
    @setFileStats entry
    unless @fileInRepo(entry) || @isImdoneConfig(entry) || @isImdoneIgnore(entry)
      @fileAdded entry

  watchPath: (entry) ->
    unless @getWatcher entry || entry.isFile()
      path = entry.getPath()
      log "Watching path #{path}"
      @watched.add path, entry.onDidChange =>
        return if @paused
        log "dirChanged #{entry.getPath()}"
        @dirChanged entry

  removeDeletedEntries: (entry) ->
    dirPath = entry.getPath() + sep
    for path, stats of @files when path.indexOf(dirPath) == 0
      exists = fs.existsSync path
      @fileDeleted path unless exists
    @watched.removeDeletedChildren entry.getPath()


  updateChangedChildren: (dir, cb) ->
    
    hasChange = false
    
    processEntry = (entry, cb) =>
      if entry.isFile()
        @isReallyChanged entry, (err, changed) =>
          return cb err if err
          if changed
            @fileChanged entry
            hasChange = true
          cb()

    # BACKLOG: Use fs.list gh:263 id:70
    dir.getEntries (err, entries) =>
      async.each entries, processEntry, (err) =>
        log "#{dir.getPath()} hasChange:#{hasChange}"
        cb err, hasChange

  dirChanged: (entry) ->
    if (fs.existsSync(entry.getPath()))
      @hasNewChildren entry, (err, hasNew) =>
        log "*** #{entry.getPath()} exists and hasNewChildren: #{hasNew}"
        if hasNew && !err
          @watchDir entry
        else @updateChangedChildren entry, (err, changed) =>
          @removeDeletedEntries entry unless changed
      # on mkdir this fires once for the parent of the dir added
      # on touch this fires twice for the parent of the file touched
      # on file modified this fires twice for parent of the file modified
      # dirChanged fires twice per file and dir added in the entry
    else
      # dirChanged fires once per child file and dir in the deleted entry and once for the parrent entry
      log "removing children of #{entry.getPath()}"
      @removeDeletedEntries entry
      @watched.removeDir(entry.getPath())

  fileChanged: (entry) ->
    log "fileChanged #{entry.getPath()}"
    relPath = @repo.getRelativePath entry.getPath()
    file = @repo.getFile(relPath) || relPath
    if (@isImdoneConfig(entry) || @isImdoneIgnore(entry))
      @repo.emitConfigUpdate()
    else
      @repo.fileOK file, (err, ok) =>
        return if (err || !ok)
        @repo.readFile file, (err, file) =>
          @repo.emitFileUpdate file

  fileAdded: (entry) ->
    log "fileAdded #{entry.getPath()}"
    relPath = @repo.getRelativePath entry.getPath()
    file = new File(repoId: @repo.getId(), filePath: relPath, languages: @repo.languages)
    @repo.fileOK file, (err, stat) =>
      return if (err || !stat)
      return if (stat.mtime <= file.getModifiedTime())
      @repo.readFile file, (err, file) =>
        @repo.emitFileUpdate file

  fileDeleted: (path) ->
    log "fileDeleted #{path}"
    relPath = @repo.getRelativePath path
    file = new File(repoId: @repo.getId(), filePath: relPath, languages: @repo.languages)
    @removeFile path
    @repo.removeFile file
    @repo.emitFileUpdate file

module.exports =  (repo) ->
  repo = fsStore(repo, fs)

  _init = repo.init
  repo.init = (cb) ->
    _init.call repo, (err, files) ->
      repo.initWatcher cb, files
      cb(err, files) if cb

  _destroy = repo.destroy
  repo.destroy = () ->
    repo.watcher.close() if repo.watcher
    _destroy.apply repo

  _refresh = repo.refresh
  repo.refresh = (cb) ->
    repo.watcher.close() if repo.watcher
    _refresh.call repo, (err, files) ->
      repo.initWatcher cb, files
      cb(err, files) if cb

  repo.initWatcher = (cb, files) ->
    repo.watcher = new Watcher(repo)
    cb = (() ->) unless cb
    cb null, files

  repo.pause = ->
    repo.watcher.pause() if repo.watcher && repo.watcher.pause

  repo.resume = ->
    repo.watcher.resume() if repo.watcher && repo.watcher.resume

  repo
