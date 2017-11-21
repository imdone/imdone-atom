worker = new Worker('./repo-worker')
repoActions =
  'isImdoneIOProject'
  'renameList'
  'addList'
  'fileStats'
// clientActions
// pluginManagerActions
module.exports = WorkerBackedRepo =
  sendToWorker: (func, params...) ->
    worker.send({func, params})
