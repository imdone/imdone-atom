fs          = require 'fs'
fsStore     = require 'imdone-core/lib/mixins/repo-fs-store'
File        = require 'imdone-core/lib/file'
constants   = require 'imdone-core/lib/constants'
PathWatcher = require 'pathwatcher'
sep         = require('path').sep
log         = require './log'

class Watcher
  constructor: (@repo)->
    dir = (dir for dir in atom.project.getDirectories() when dir.getPath() is @repo.path)[0]
    @watched = {}
    @watchDir dir

  close: () -> @closeWatcher path for path, watcher of @watched

  closeWatcher: (path) ->
    log "Stopped watching #{path}"
    @watched[path].close()
    delete @watched[path]

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
    # DONE:0 Make sure the digest has changed
    file = (file for file in entry.getParent().getEntriesSync() when entry.getPath() == file.getPath())[0]
    watcher = @watched[entry.getPath()]
    digest = file.getDigestSync()
    log "#{file.getPath()}:#{digest}"
    return true unless file && watcher
    return false unless digest != watcher.digest
    watcher.digest = digest
    true

  fileInRepo: (entry) ->
    relPath = @repo.getRelativePath entry.getPath()
    @repo.getFile(relPath)

  watchDir: (dir) ->
    @watchPath dir
    dir.getEntries (err, entries) =>
      @watchDir _dir for _dir in entries when (_dir.isDirectory() && !@shouldExclude(_dir.getPath()))
      @watchFile file for file in entries when (file.isFile() && !@shouldExclude(file.getPath()))

  watchFile: (entry) ->
    @watchPath entry
    @fileAdded entry unless @fileInRepo(entry) || @isImdoneConfig(entry) || @isImdoneIgnore(entry)

  watchPath: (entry) ->
    path = entry.getPath()
    unless @watched[path]
      log "Watching path #{path}"
      @watched[path] = PathWatcher.watch path, (event) =>
        if entry.isDirectory()
          @dirChanged(entry) if event == 'change'
          @dirRenamed(entry) if event == 'rename'
          @dirDeleted(entry) if event == 'delete'
        else
          @fileChanged(entry) if event == 'change'
          @fileRenamed(entry) if event == 'rename'
          @fileDeleted(entry) if event == 'delete'

  dirChanged: (entry) ->
    log "dirChanged #{entry.getPath()}"
    @watchDir entry

  dirRenamed: (entry) ->
    log "dirRenamed #{entry.getPath()}"

  dirDeleted: (entry) ->
    log "dirDeleted #{entry.getPath()}"
    @closeWatcher entry.getPath()
    dirPath = entry.getPath() + sep
    for path, watcher of @watched when path.indexOf(dirPath) == 0
      relPath = @repo.getRelativePath path
      file = new File(filePath: relPath)
      @repo.removeFile file
      @repo.emitFileUpdate file
      @closeWatcher path

  fileChanged: (entry) ->
    log "fileChanged #{entry.getPath()}"
    return unless @isReallyChanged entry
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
    return unless @isReallyChanged entry
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
