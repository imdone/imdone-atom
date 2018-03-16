const notifyer = require('node-notifier')
const path = require('path')
const moment = require('moment')
const Task = require('imdone-core/lib/task')
const notifier = require('node-notifier')
const packagePath = atom.packages.resolvePackagePath('imdone-atom')
const remote = require('electron').remote

class Reminders {
  constructor(repo) {
    this.repo = repo
    this.listen()
  }

  destory() {
    clearInterval(this.interval)
  }

  listen() {
    const repo = this.repo
    this.interval = setInterval(() => {
      repo.getTasks().forEach(task => {
        if (!task.meta.remind) return
        const reminder = moment(task.meta.remind[0])
        if (reminder.diff(moment()) > 0) return
        this.notify(task)
      })
    }, 20000)
  }

  // DOING: Show imdone logo in notifications. id:142 gh:356 ic:gh
  notify(task) {
    notifier.notify(
      {
        title: 'imdone reminder',
        message: task.text,
        icon: path.join(packagePath, 'images', 'imdone-logo-banner.png'), // Absolute path (doesn't work on balloons)
        sound: 'Tink', // Only Notification Center or Windows Toasters
        actions: 'Show'
      },
      (err, response, metadata) => {
        remote.getCurrentWindow().show()
        const filePath = this.repo.getFullPath(task.source.path)
        atom.workspace.open(filePath, {split: 'left'}).then( () => {
          const textEditor = atom.workspace.getActiveTextEditor()
          const position = [task.line-1, 0]
          textEditor.setCursorBufferPosition(position, {autoscroll: false})
          textEditor.scrollToCursorPosition({center: true})
        })
        // Response is response from notification
      }
    )
  }
}

module.exports = Reminders
