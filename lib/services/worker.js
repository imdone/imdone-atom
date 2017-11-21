const chokidar = require('chokidar')
let watcher

process.on('message', ({event, data}) => {
  if (event === 'initWatcher') return initWatcher(data)
  if (event === 'destroyWatcher') return destroyWatcher()
})
const send = (event, data) => process.send({event, data})
const initWatcher = function (repoPath) {
  destroyWatcher()
  watcher = chokidar.watch(repoPath, {
    ignored: function(path) {
      return false;
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
