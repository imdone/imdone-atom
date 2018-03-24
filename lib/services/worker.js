const chokidar = require('chokidar')
const ignore = require('ignore')
const log = require('debug')('imdone-atom:worker')
let watcher
const _path = require('path')
let relative = _path.relative


process.on('message', ({event, data}) => {
  console.log('log',{event, data})
  if (event === 'refresh') return refresh()
  if (event === 'initWatcher') return initWatcher(data)
  if (event === 'destroyWatcher') return destroyWatcher()
})
const send = (event, data) => {
  log('Sending event:${event} with data:${JSON.stringify(data)}')
  process.send({event, data})
}
const initWatcher = function ({path, exclude, ignorePatterns}) {
  console.log(`initializing watcher for ${path}`)
  const ig = ignore().add(ignorePatterns)
  let repoPath = path
  destroyWatcher()
  watcher = chokidar.watch(repoPath, {
    ignored: function(path) {
      console.log(`check if ${path} is ignored`)
      let relPath = relative(repoPath, path)
      if (relPath.indexOf('.imdone') > -1) return false
      if (relPath && ig.ignores(relPath)) return true
      if (!exclude) return false
      console.log(`${path} is good`)
      for (let i=0;i < exclude.length;i++) {
        try {
          let pattern = exclude[i]
          let shouldExclude = (new RegExp(pattern)).test(relPath)
          if (shouldExclude) return shouldExclude
        } catch (e) {
          console.log('error', e)
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

const refresh = function () {
  destroyWatcher()
  send('refresh', {})
}
