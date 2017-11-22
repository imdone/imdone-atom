const chokidar = require('chokidar')
const ignore = require('ignore')
let watcher
let relative = require('path').relative

process.on('message', ({event, data}) => {
  send('log',{event, data})
  if (event === 'initWatcher') return initWatcher(data)
  if (event === 'destroyWatcher') return destroyWatcher()
})
const send = (event, data) => process.send({event, data})
const initWatcher = function ({path, exclude, ignorePatterns}) {
  const ig = ignore().add(ignorePatterns)
  let repoPath = path
  destroyWatcher()
  watcher = chokidar.watch(repoPath, {
    ignored: function(path) {
      let relPath = relative(repoPath, path)
      if (relPath && ig.ignores(relPath)) return true
      if (!exclude) return false
      for (let i=0;i < exclude.length;i++) {
        try {
          let pattern = exclude[i]
          let shouldExclude = (new RegExp(pattern)).test(relPath)
          if (shouldExclude) return shouldExclude
        } catch (e) {
          send('error', e)
        }
      }
    },
    persistent: true
  });
  watcher
  .on('add', (path) => send('add', path))
  .on('addDir', (path) => send('addDir', path))
  .on('change', (path) => send('change', path))
  .on('unlink', (path) => send('unlink', path))
  .on('unlinkDir', (path) => send('unlinkDir', path))
  .on('error', (error) => send('error', error));
}

const destroyWatcher = function () {
  if (!watcher) return
  watcher.close()
}
