const _ = require('lodash')
const path = require('path')
const moment = require('moment')
const Task = require('imdone-core/lib/task')
const packagePath = atom.packages.resolvePackagePath('imdone-atom')
const remote = require('electron').remote
const schedule = require('node-schedule')
const os = require('os')

class Reminders {
  constructor(repo) {
    this.jobs = []
    this.repo = repo
    this.schedule()
  }

  clearSchedule() {
    this.jobs.forEach(job => job.cancel())
    this.jobs = []
  }

  destory() {
    this.clearSchedule()
  }

  schedule() {
    this.clearSchedule()
    const repo = this.repo
    repo.getTasks().forEach(task => {
      if (!task.meta.remind) return
      if (task.meta.completed) return
      const reminder = moment(task.meta.remind[0])
      if (reminder.diff(moment()) < 0) return
      const job = schedule.scheduleJob(reminder.toDate(), () => {
        this.notify(task, job)
        task.meta.remind[0] = reminder.add(5, 'minutes').format()
        task.updateMetaData()
        repo.modifyTask(task, (err) => repo.emit('tasks.updated', [task]))
      });
      this.jobs.push(job)
    })
    console.log(`reminders: ${this.jobs.length}`)
  }

  notify(task, job) {
    let remindDate = moment(task.meta.remind[0]).format('llll')
    const config = {
        title: 'imdone reminder',
        body: task.getText({stripMeta: true}) + '\n' + remindDate,
        icon: path.join(packagePath, 'images', 'imdone-logo-banner.png') // Absolute path (doesn't work on balloons)
    }
    const notification = new window.Notification(config.title, config)
    notification.onclick = (evt) => {
      job.cancel()
      remote.getCurrentWindow().show()
      const filePath = this.repo.getFullPath(task.source.path)
      atom.workspace.open(filePath, {split: 'left'}).then( () => {
        const textEditor = atom.workspace.getActiveTextEditor()
        const position = [task.line-1, 0]
        textEditor.setCursorBufferPosition(position, {autoscroll: false})
        textEditor.scrollToCursorPosition({center: true})
      })
    }
  }
}

module.exports = Reminders
