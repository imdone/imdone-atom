const notifyer = require('node-notifier')
const path = require('path')
const moment = require('moment')
const Task = require('imdone-core/lib/task')
const notifier = require('node-notifier')
const PackageManager = require('atom').PackageManager
const remote = require('electron').remote

class Reminders {
  constructor(repo) {
    this.repo = repo
    this.listen()
    // notifier.on('click', function(notifierObject, options) {
    //   debugger
    // // Triggers if `wait: true` and user clicks notification
    // });
    //
    // notifier.on('timeout', function(notifierObject, options) {
    //   debugger
    //   // Triggers if `wait: true` and notification closes
    // });
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

  // DOING: Show imdone logo in notifications. remind:2018-03-15T02:05:05-04:00
  notify(task) {
    notifier.notify(
      {
        title: 'imdone reminder',
        message: task.text,
        // icon: path.join(__dirname, 'coulson.jpg'), // Absolute path (doesn't work on balloons)
        sound: 'Tink', // Only Notification Center or Windows Toasters
        // wait: true, // Wait with callback, until user action is taken against notification
        sticky: true,
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
