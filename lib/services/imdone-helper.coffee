ImdoneRepo = require 'imdone-core/lib/repository'
# fsStore = require 'imdone-core/lib/mixins/repo-watched-fs-store'
atomFsStore = require './atom-watched-fs-store'
fsStore = require 'imdone-core/lib/mixins/repo-watched-fs-store'
path = require 'path'
configHelper = require './imdone-config'
repos = {}

module.exports =
  getRepo: (pathname, uri) ->
    # TODO:0 This returns repo and connectorManager, but we could use the connectorManager contained in the repo throughout id:24
    return repos[pathname] if repos and repos[pathname]
    imdoneRepo = @fsStore(new ImdoneRepo(pathname))
    @excludeVcsIgnoresMixin(imdoneRepo)
    repos[pathname] = require('./imdoneio-store') imdoneRepo
    repos[pathname]

  destroyRepos: () -> repo.repo.destroy() for path, repo of repos

  fsStore: (repo) ->
    fsStore = atomFsStore if configHelper.getSettings().useAlternateFileWatcher
    fsStore(repo)

  excludeVcsIgnoresMixin: (imdoneRepo) ->
    repoPath = imdoneRepo.getPath()
    vcsRepo = @repoForPath repoPath
    return unless vcsRepo
    _shouldExclude = imdoneRepo.shouldExclude
    shouldExclude = (relPath) ->
      return true if vcsRepo.isPathIgnored(relPath)
      _shouldExclude.call imdoneRepo, relPath

    imdoneRepo.shouldExclude = shouldExclude if configHelper.getSettings().excludeVcsIgnoredPaths
    atom.config.observe "excludeVcsIgnoredPaths", (exclude) ->
      imdoneRepo.shouldExclude = if exclude then shouldExclude else _shouldExclude
      imdoneRepo.refresh() if imdoneRepo.initialized

  repoForPath: (repoPath) ->
    for projectPath, i in atom.project.getPaths()
      if repoPath is projectPath or repoPath.indexOf(projectPath + path.sep) is 0
        return atom.project.getRepositories()[i]
    null
