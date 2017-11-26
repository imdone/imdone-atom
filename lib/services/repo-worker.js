const Repo = 
let repo

process.on('message', ({event, data}) => {
  send('log',{event, data})
  if (CMD_EVENTS[event]) {
    CMD_EVENTS[event](data)
  }
})

const CMD_EVENTS = {
  create: function ({path, config}) {
    repo = new Repo()
  }

}
  // 'create',
  // 'init',
  // 'refresh',
  // 'modifyTask',
  // 'modifyConfig',
