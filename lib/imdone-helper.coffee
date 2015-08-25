ImdoneRepo = require 'imdone-core/lib/repository'
fsStore = require 'imdone-core/lib/mixins/repo-watched-fs-store'
path = require 'path'

module.exports =
  newImdoneRepo: (pathname, uri) ->
    imdoneRepo = fsStore(new ImdoneRepo(pathname))
    @excludeVcsIgnoresMixin(imdoneRepo)
    imdoneRepo

  excludeVcsIgnoresMixin: (imdoneRepo) ->
    keyPath = 'imdone-atom.excludeVcsIgnoredPaths'
    repoPath = imdoneRepo.getPath()
    vcsRepo = @repoForPath repoPath
    return unless vcsRepo
    _shouldExclude = imdoneRepo.shouldExclude
    shouldExclude = (relPath) ->
      return true if vcsRepo.isPathIgnored(relPath)
      _shouldExclude.call imdoneRepo, relPath

    imdoneRepo.shouldExclude = shouldExclude if atom.config.get(keyPath)
    atom.config.observe keyPath, (exclude) ->
      imdoneRepo.shouldExclude = if exclude then shouldExclude else _shouldExclude
      imdoneRepo.refresh() if imdoneRepo.initialized

  repoForPath: (repoPath) ->
    for projectPath, i in atom.project.getPaths()
      if repoPath is projectPath or repoPath.indexOf(projectPath + path.sep) is 0
        return atom.project.getRepositories()[i]
    null
