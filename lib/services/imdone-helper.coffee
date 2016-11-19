ImdoneRepo = require 'imdone-core/lib/repository'
# fsStore = require 'imdone-core/lib/mixins/repo-watched-fs-store'
atomFsStore = require './atom-watched-fs-store'
fsStore = require 'imdone-core/lib/mixins/repo-watched-fs-store'
path = require 'path'
configHelper = require './imdone-config'
repos = {}

module.exports =
  getRepo: (pathname, uri) ->
    # TODO: This returns repo and connectorManager, but we could use the connectorManager contained in the repo throughout id:25
    return repos[pathname] if repos and repos[pathname]
    imdoneRepo = @fsStore(new ImdoneRepo(pathname))
    @excludeVcsIgnoresMixin imdoneRepo
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
    imdoneRepo.shouldExclude = (relPath) ->
      return _shouldExclude.call imdoneRepo, relPath unless configHelper.getSettings().excludeVcsIgnoredPaths
      vcsIgnored = vcsRepo.isPathIgnored relPath
      return true if vcsIgnored
      _shouldExclude.call imdoneRepo, relPath

  repoForPath: (repoPath) ->
    for projectPath, i in atom.project.getPaths()
      if repoPath is projectPath or repoPath.indexOf(projectPath + path.sep) is 0
        return atom.project.getRepositories()[i]
    null
