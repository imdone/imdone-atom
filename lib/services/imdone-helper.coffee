ImdoneRepo = require 'imdone-core/lib/repository'
atomFsStore = require './atom-watched-fs-store'
# fsStore = require 'imdone-core/lib/mixins/repo-watched-fs-store'
fsStore = require './worker-watched-fs-store'
path = require 'path'
getSettings = require('./imdone-config').getSettings
repos = {}

module.exports =
  getRepo: (pathname, uri) ->
    # TODO: This returns repo and connectorManager, but we could use the connectorManager contained in the repo throughout id:2 gh:238
    return repos[pathname] if repos and repos[pathname]
    imdoneRepo = @fsStore(new ImdoneRepo(pathname))
    @excludeVcsIgnoresMixin imdoneRepo
    repos[pathname] = require('./imdoneio-store') imdoneRepo
    repos[pathname]

  destroyRepos: () ->
    for path, repo of repos
      repo.destroy()

  fsStore: (repo) ->
    fsStore = atomFsStore if getSettings().useAlternateFileWatcher
    fsStore(repo)

  excludeVcsIgnoresMixin: (imdoneRepo) ->
    repoPath = imdoneRepo.getPath()
    vcsRepo = @repoForPath repoPath
    return unless vcsRepo
    _shouldExclude = imdoneRepo.shouldExclude
    imdoneRepo.shouldExclude = (relPath) ->
      if getSettings().excludeVcsIgnoredPaths && vcsRepo
        vcsIgnored = vcsRepo.isPathIgnored relPath
        return true if vcsIgnored
      _shouldExclude.call imdoneRepo, relPath

  repoForPath: (repoPath) ->
    for projectPath, i in atom.project.getPaths()
      if repoPath is projectPath or repoPath.indexOf(projectPath + path.sep) is 0
        return atom.project.getRepositories()[i]
    null
