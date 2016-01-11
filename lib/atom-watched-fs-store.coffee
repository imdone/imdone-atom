fs          = require 'fs'
fsStore     = require 'imdone-core/lib/mixins/repo-fs-store'
File        = require 'imdone-core/lib/file'
constants   = require 'imdone-core/lib/constants'
sep         = require('path').sep
log         = require './log'
{CompositeDisposable} = require 'atom'


class HashCompositeDisposable extends CompositeDisposable
  constructor: ->
    @watched = {}
    super()

  add: (path, disposable) ->
    @watched[path] = {disposables:[]} unless @watched[path]
    @watched[path].disposables.push disposable
    super disposable

  remove: (path) ->
    return unless @watched[path] && @watched[path].disposables
    log "disposable removed for #{path}"
    super(disposable) for disposable in @watched[path].disposables
    delete @watched[path]

  removeChildren: (dir) ->
    @remove dir
    dir += sep
    @remove path for path, watched of @watched when path.indexOf(dir) == 0

  get: (path) ->
    return @watched[path]

  dispose: () ->
    @watched = {}
    super()

class Watcher
  constructor: (@repo)->
    dir = (dir for dir in atom.project.getDirectories() when dir.getPath() is @repo.path)[0]
    @watched = new HashCompositeDisposable
    @watchDir dir

  close: () -> @closeWatcher path for path, watcher of @watched.watched

  closeWatcher: (path) ->
    log "Stopped watching #{path}"
    @watched.remove path

  shouldExclude: (path) ->
    relPath = @repo.getRelativePath(path);
    return false if (relPath.indexOf('.imdone') == 0)
    @repo.shouldExclude(relPath);

  isImdoneConfig: (entry) ->
    relPath = @repo.getRelativePath entry.getPath()
    relPath.indexOf(constants.CONFIG_FILE) > -1

  isImdoneIgnore: (entry) ->
    relPath = @repo.getRelativePath entry.getPath()
    relPath.indexOf(constants.IGNORE_FILE) > -1

  isReallyChanged: (entry) ->
    # DONE:0 Make sure the digest has changedd
    file = (file for file in entry.getParent().getEntriesSync() when entry.getPath() == file.getPath())[0]
    watcher = @watched.get entry.getPath()
    return true unless file && watcher
    digest = file.getDigestSync()
    log "#{file.getPath()}:#{digest}"
    return false unless digest != watcher.digest
    watcher.digest = digest
    true

  isNewEntry: (entry) ->
    return true unless @fileInRepo(entry) || @isImdoneConfig(entry) || @isImdoneIgnore(entry) || @watched.get entry.getPath()

  hasNewChildren: (entry) ->
    newEntries = (entry for entry in entry.getEntriesSync() when @isNewEntry(entry))
    newEntries && newEntries.length > 0

  fileInRepo: (entry) ->
    relPath = @repo.getRelativePath entry.getPath()
    @repo.getFile(relPath)

  watchDir: (dir) ->
    @watchPath dir
    entries = dir.getEntriesSync()
    @watchDir _dir for _dir in entries when (_dir.isDirectory() && !@shouldExclude(_dir.getPath()))
    @watchFile file for file in entries when (file.isFile() && !@shouldExclude(file.getPath()))

  watchFile: (entry) ->
    @watchPath entry
    unless @fileInRepo(entry) || @isImdoneConfig(entry) || @isImdoneIgnore(entry)
      @fileAdded entry

  watchPath: (entry) ->
    path = entry.getPath()
    unless @watched.get path
      log "Watching path #{path}"
      if entry.isDirectory()
        @watched.add path, entry.onDidChange =>
          @dirChanged entry
      if entry.isFile()
        @watched.add path, entry.onDidChange =>
          @fileChanged entry
        @watched.add path, entry.onDidRename =>
          @fileRenamed entry
        @watched.add path, entry.onDidDelete =>
          @fileDeleted entry

  dirChanged: (entry) ->
    log "dirChanged #{entry.getPath()}"
    if (fs.existsSync(entry.getPath()))
      @watchDir entry if (@hasNewChildren(entry))
      # on mkdir this fires once for the parent of the dir added
      # on touch this fires twice for the parent of the file touched
      # on file modified this fires twice for parent of the file modified
      # dirChanged fires twice per file and dir added in the entry
    else
      # dirChanged fires once per child file and dir in the deleted entry and once for the parrent entry
      log "removing children of #{entry.getPath()}"
      @watched.removeChildren(entry.getPath())


  dirDeleted: (entry) ->
    log "dirDeleted #{entry.getPath()}"
    @closeWatcher entry.getPath()
    dirPath = entry.getPath() + sep
    return unless @watched && @watched.watched
    for path, watcher of @watched.watched when path.indexOf(dirPath) == 0
      relPath = @repo.getRelativePath path
      file = new File(filePath: relPath)
      @repo.removeFile file
      @repo.emitFileUpdate file
      @closeWatcher path

  fileChanged: (entry) ->
    return unless @isReallyChanged entry
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
    return unless @isReallyChanged entry
    log "fileAdded #{entry.getPath()}"
    relPath = @repo.getRelativePath entry.getPath()
    file = new File(repoId: @repo.getId(), filePath: relPath, languages: @repo.languages)
    @repo.fileOK file, (err, stat) =>
      return if (err || !stat)
      return if (stat.mtime <= file.getModifiedTime())
      @repo.readFile file, (err, file) =>
        @repo.emitFileUpdate file

  fileRenamed: (entry) ->
    log "fileRenamed #{entry.getPath()}"

  fileDeleted: (entry) ->
    log "fileDeleted #{entry.getPath()}"
    relPath = @repo.getRelativePath entry.getPath()
    file = new File(repoId: @repo.getId(), filePath: relPath, languages: @repo.languages)
    @repo.removeFile file
    @closeWatcher entry.getPath()
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

  repo
