const moment = require('moment')
const chrono = require('chrono-node')
const Task = require('imdone-core/lib/task')
const Repository = require('imdone-core/lib/repository')
const _ = require('lodash')

class Transformer {
  constructor (opts) {
    Object.assign(this, opts)
  }

  toJSON() {
    const pattern = this.pattern && this.pattern.toString()
    const clone = Object.assign({}, this)
    delete clone.config
    return Object.assign(clone,{pattern})
  }

  parseDate(text, ref) {
    if (ref) ref = moment(ref)
    let results = new chrono.parse(text, ref)
    if (!results[0]) results = new chrono.parse('now', ref)
    return moment(results[0].start.date())
  }
}

const getTransformers = function (config) {
  return [
    new Transformer({
      config,
      name: "variable",
      pattern: /\$(\w+)/,
      vars: {
        now: (instance) => instance.parseDate('now').format(),
        today: (instance) => instance.parseDate('now').format('YYYY-MM-DD')
      },
      exec: function (task) {
        return task.text.replace(this.pattern, (match, varName) => {
          if (!this.vars[varName]) return varName
          return this.vars[varName](this)
        })
      }
    }),
    new Transformer({
      config,
      name: "plain language due",
      pattern: /due\s.*?\./i,
      exec: function (task) {
        return task.text.replace(this.pattern, (match) => {
          const due = this.parseDate(match).format()
          return `due:${due}`
        })
      }
    }),
    new Transformer({
      config,
      name: "plain language remind",
      pattern: /remind me\s.*?(before)?\./i,
      exec: function (task) {
        return task.text.replace(this.pattern, (match, before) => {
          let dueDate
          if (before && task.meta.due) {
            dueDate = task.meta.due[0]
            match = match.replace('before', 'ago')
          }
          const remind = this.parseDate(match, dueDate).format()
          return `remind:${remind}`
        })
      }
    }),
    new Transformer({
      config: _.get(config, 'transformers.autocreate'),
      name: "autocreate",
      exec: function (task) {
        if (!this.config || task.meta.created || task.meta.completed) return task.text
        const excludeLists = this.config.exclude
        const filter = this.config.filter
        if (!excludeLists && !filter) return task.text
        if (excludeLists && excludeLists.includes(task.list)) return task.text
        if (filter && Repository.query([task], filter).length == 0 ) return task.text
        task.addMetaData("created", this.parseDate('now').format())
        return task.text
      },
      pattern: /^((?!\screated:).)*$/
    }),
    new Transformer({
      config: _.get(config, 'transformers.autocomplete'),
      name: "autocomplete",
      exec: function (task) {
        if (!this.config || task.meta.completed) return task.text
        const list = this.config.list
        const filter = this.config.filter
        if (!list && !filter) return task.text
        if (list && (task.list !== list)) return task.text
        if (filter && Repository.query([task], filter).length == 0 ) return task.text
        task.addMetaData("completed", this.parseDate('now').format())
        task.removeMetaData('remind')
        return task.text
      },
      pattern: /^((?!\scompleted:).)*$/
    })
  ]
}

const transformTask = function (task, transformers) {
  const text = task.text
  transformers.forEach(transformer => {
    task.text = transformer.exec(task)
    if (text === task.text) return
    task.modified = true
    task.parseTodoTxt()
  })
  return task
}

const transformTasks = function (config, tasks) {
  const transformers = getTransformers(config)
  tasks = tasks.map(task => transformTask(task, transformers))
  return tasks.filter(task => task.modified)
}

module.exports = {
  getTransformers,
  transformTask,
  transformTasks,
  Transformer
}
