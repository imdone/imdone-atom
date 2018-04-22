
[![apm](https://img.shields.io/apm/v/imdone-atom.svg)]()
[![apm](https://img.shields.io/apm/dm/imdone-atom.svg)](https://atom.io/packages/imdone-atom)  

![made](https://octicons.glitch.me/svg/code.svg?size=16&color=000000) with ![love](https://octicons.glitch.me/svg/heart.svg?size=16&color=ff0000) by
<a href="https://imdone.io/"><img src="https://imdone.io/images/logos/imdone-logo.svg" width=16> imdone.io</a>

**A kanban board with an invisible user interface. It's cards and lists are made from TODOs in your code, markdown and text files.**
Use `alt(⌥)+t` to open your project's board.

Integrate your TODO comments into your team's issue tracker or backlog with **[imdone.io](https://imdone.io)**.

Vote on new features! [![vote on features](https://img.shields.io/github/issues/imdone/imdone-atom/feature.svg)](https://github.com/imdone/imdone-atom/issues?q=is%3Aissue+is%3Aopen+label%3Afeature+sort%3Acreated-desc)
![screen shot 2018-01-20 at 5 24 12 pm](https://user-images.githubusercontent.com/233505/35189496-c05ed71e-fe08-11e7-9390-6e8fb999d1f7.png)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
### **Table of Contents**

- [Track your TODO comments in a kanban board](#track-your-todo-comments-in-a-kanban-board)
- [NEW for imdone.io subscribers!!!](#new-for-imdoneio-subscribers)
  - [$now and $today variable replacement](#now-and-today-variable-replacement)
  - [Plain text remind: and due: timestamps](#plain-text-remind-and-due-timestamps)
  - [OS notifications for remind:[timestamp] metadata](#os-notifications-for-remindtimestamp-metadata)
  - [Auto completed:[timestamp]](#auto-completedtimestamp)
- [Task Board Features](#task-board-features)
  - [Filtering your board](#filtering-your-board)
  - [Ignoring all tasks in a list](#ignoring-all-tasks-in-a-list)
  - [Delete all visible tasks](#delete-all-visible-tasks)
  - [Open all files for visible tasks](#open-all-files-for-visible-tasks)
  - [Using tags in your TODO comments](#using-tags-in-your-todo-comments)
  - [Using contexts and @name syntax](#using-contexts-and-name-syntax)
  - [metadata](#metadata)
  - [Adding and removing TODO tokens](#adding-and-removing-todo-tokens)
  - [Global journal](#global-journal)
  - [Project journal](#project-journal)
  - [Ignoring files](#ignoring-files)
- [Install](#install)
- [Commands](#commands)
- [Settings](#settings)
- [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

Track your TODO comments in a kanban board
----
Imdone finds [TODO comments](https://medium.com/imdoneio/3-reasons-why-todo-comments-are-a-good-thing-c2cf3d7b7c2b) in your project and organizes them in a drag and drop kanban board that can integrate with [GitHub](https://imdone.io/), [waffle.io](https://imdone.io/) or whatever you want using [imdone.io](https://imdone.io).  It's great for keeping track of your work or better yet identifying, organizing and analyzing technical debt so it can be integrated into the product backlog.

imdone-atom recognizes the common TODO style comments we're all used to, with the added flexibility of todo.txt and markdown syntax.  A complete syntax guide can be found in the [task formats](https://github.com/imdone/imdone-core#imdone-format) section of the [imdone-core README.md](https://github.com/imdone/imdone-core#imdone-format).

**Try adding some TODO's and press Alt (⌥ Option)+T to see your board!**

**A TODO in javascript**
``` javascript
// TODO: Refactor and DRY up
```

**A TODO in markdown**
``` markdown
#TODO: As a user I would like to ... so that ...
```

In code files, imdone recognizes any comment line after a TODO as a description and adds it to the card.  imdone stops looking for description lines if it encounters a new TODO or a line of code.

In non code files, imdone recognizes any line after a TODO as a description and adds it to the card.  imdone stops looking for description lines if it encounters a new TODO or a blank line.

Checklists in your descriptions will render in your cards and will live update your file as they're checked.
``` javascript
// TODO: Refactor and DRY up
// - [x] Replace all duplicate code with this method
// - [ ] Make sure all tests are up to date
```

NEW for [imdone.io](https://imdone.io) subscribers!!!
----
### $now and $today variable replacement
- replace `$now` with with the current timestamp (ex. `2018-03-18T09:37:49-06:00`)
- replace `$today` with the current date (ex. `2018-03-18`)

### Plain text remind: and due: timestamps
Use plain text to set reminders and due dates for your tasks. Uses [date.js](https://www.npmjs.com/package/date.js#examples).
- replace `due tomorrow at noon.`
  - with **due:[timestamp of tomorrow at noon]**
  - (ex. `due:2018-03-19T10:00:00-06:00`)
- replace `remind me in 2 hours.`
  - with **due:[timestamp in 2 hours]**
  - (ex. `remind:2018-03-18T11:45:06-06:00`)
- replace `due tomorrow at noon. remind me 30 min before.`
  - with **due:[timestamp of tomorrow at noon] remind:[timestamp for 30 minutes before due]**
  - (ex. `due:2018-03-19T10:00:00-06:00  remind:2018-03-19T11:30:00-04:00`)

### OS notifications for remind:[timestamp] metadata
If you set a reminder for your task, you'll receive an OS notification that when clicked, will taske you to the task in the file containing it.  

<img width="353" alt="screen shot 2018-03-23 at 9 09 05 am" src="https://user-images.githubusercontent.com/233505/37837111-01cee9e0-2e7a-11e8-8aab-6eb9115b5dea.png">

### Auto completed:[timestamp] and Auto created:[timestamp]
Adding this section to your `.imdone/config.json` will cause all tasks in `DONE` to have a `completed:[timestamp]` added to the task text, and tasks not in `DONE` to have a `created:[timestamp]` added to the task text.
See [rql](https://github.com/persvr/rql) for filter syntax.
```json
"transformers": {
  "autocomplete": {
    "filter": "eq(list,DONE)"
  },
  "autocreate": {
    "filter": "ne(list,DONE)"
  }
}
```

Task Board Features
----
### Filtering your board
imdone uses [rql](https://github.com/persvr/rql) to filter your board. Click on the tags, contexts or the lightbulb icon next to metadata or the filename to see some examples.
You can query for any property of a task. If the rql query doesn't return a result the filter will be treated as a regular expression and matched agains task.rawTask.

Metadata fields with the keys "created", "completed", "due" and "remind" will be added as date fields to the task so you can filter with lt() and gt() (e.g. "gt(due,date:2018-04-20)")
```json
{
   "text": "Remember to update changelog before +publishing +package @piascikj gh:237 id:66",
   "list": "TODO",
   "order": "",
   "hasColon": true,
   "line": 568,
   "id": "74a2ceff5d820f71574fbc2c8f7a6fff10fddcc9",
   "repoId": "/Users/jesse/projects/imdone-atom",
   "source": {
      "path": "CHANGELOG.md",
      "id": "CHANGELOG.md",
      "repoId": "/Users/jesse/projects/imdone-atom",
      "type": "File",
      "ext": "md",
      "lang": "markdown",
      "modified": false,
      "modifiedTime": "2018-04-03T17:58:15.523Z"
   },
   "type": "HASHTAG",
   "tags": [
      "publishing",
      "package"
   ],
   "context": [
      "piascikj"
   ],
   "meta": {
      "gh": [
         "237"
      ],
      "id": [
         "66"
      ],
      "due": [
        "2018-4-21"
      ]
   },
   "description": [],
   "due": "2018-04-21T06:00:00.000Z",
   "rawTask": "#TODO: Remember to update changelog before +publishing +package @piascikj gh:237 id:66"
}
```

### Ignoring all tasks in a list
Add an `ignore: true` property to the list in `.imdone/config.js` to keep tasks in the given list off the board and ignored by imdone.io integrations.
If you add the `ignore: true` property to a list in `.imdone/config.json` like this...
```json
"lists": [
  {
    "name": "ARCHIVE",
    "hidden": false,
    "ignore": true
  }
]
```

The list will look like this...

![screen shot 2018-04-04 at 12 26 46 pm](https://user-images.githubusercontent.com/233505/38326640-83770a08-3803-11e8-9dbb-d58a388f2454.png)

### Delete all visible tasks
Just click on the trash can icon and all the visible tasks will be deleted.  imdone will also get rid of any blank lines left behind!  Great for cleaning up!

### Open all files for visible tasks
Click on the lightning bolt icon and open all files for the visible tasks.

### Using tags in your TODO comments
imdone uses a bit of [Todo.txt format](https://github.com/ginatrapani/todo.txt-cli/wiki/The-Todo.txt-Format) (except priority), so `+bug` would be a tag.  Tags in TODO content are turned into filter links, so clicking on it will filter the board.

### Using contexts and @name syntax
You can use [Todo.txt](https://github.com/ginatrapani/todo.txt-cli/wiki/The-Todo.txt-Format)  contexts in the same way.  They'll also be turned into filter links.

### metadata
Another great benefit of using [Todo.txt format](https://github.com/ginatrapani/todo.txt-cli/wiki/The-Todo.txt-Format) is the [metadata](https://github.com/ginatrapani/todo.txt-cli/wiki/The-Todo.txt-Format#add-on-file-format-definitions). Just use the format ` key:value `, and your metadata will be listed in a table inside the task card.  We use metadata for imdone.io integrations like `gh:1` to represent github issue number 1 and `id:1` to represent imdone task id 1.

### Adding and removing TODO tokens
You can add a token by just adding an all caps list using the add list button.  If the list name matches this regex `[A-Z]+[A-Z-_]{2,}` a new token will be created.
![Adding a  TODO token](https://cloud.githubusercontent.com/assets/233505/21989108/548c5d9c-dbcf-11e6-96d0-8e2e92e73371.gif)
If the list name matches this this regex `/[\w\-]+?/`, then you will have to use the [hash style syntax](https://github.com/imdone/imdone-core#hash-style) like this...
```js
// #to-do: This is in a list that doesn't have all caps!
```
### Global journal
Configure a directory to use as a daily journal.  Open the daily journal with alt+j.  If your like me, you'll just use dropbox directory for this.  Remember, you can use TODO's in any text file if you put a `#` in front of the token, like this...
```md
This is my simple markdown journal
- #TODO: Finish this work
```

### Project journal
Configure a directory to use as a daily project journal.  Open the daily project journal with alt+p.  The daily project journal is stored in your project, and defaults to `<project-dir>/journal/${month}/${date}.md`
Use your project journal for anything, even planning your next set of features like this...
```md
- #BACKLOG: As a user I would like to use templates to add a Definition of Done to my TODOs so that I spend less time context switching to my issue tracking system.
  - [ ] Read templates from `.imdone/templates.md`
  - [ ] Replace description lines with @<template-name>
```

<!-- ### Using markdown -->
### Open files in [intellij and webstorm](https://www.jetbrains.com/products.html)
- **Open task links in [intellij](https://www.jetbrains.com/products.html) family of products with imdone-atom and [imdone intellij plugin](https://plugins.jetbrains.com/plugin/8067)!**

### Ignoring files
- Configuration setting  
You can ignore files with the "Exclude Vcs Ignored Paths" setting

- .imdoneignore  
  `.imdoneignore` is implemented using the [ignore](https://www.npmjs.com/package/ignore) package.  Each file in your projects path is tested against the rules in `.imdoneignore`.  
  To ignore all but some subdirectories, see this Stack Overflow question. [git - .gitignore exclude folder but include specific subfolder - Stack Overflow](http://stackoverflow.com/questions/5533050/gitignore-exclude-folder-but-include-specific-subfolder)

- .imdone/config.json  
  imdone will also ignore files and folders that match a regex in the `.imdone/config.json`, `exclude` array.  The array is seeded with some common excludes on first run.

  **IMPORTANT:** If your project is large (#files > 1000) consider adding an .imdoneignore file.

Install
----
```
$ apm install imdone-atom
```
or open Atom and go to Preferences > Install and search for `imdone-atom`

Commands
----
| Command Palette                       | Key Mapping      | Description                      |
|:--------------------------------------|:-----------------|:---------------------------------|
| `Imdone Atom: Tasks`                  | Alt (⌥ Option)+T | Open task board                  |
| `Imdone Atom: Todays Journal`         | Alt (⌥ Option)+J | Open todays journal file         |
| `Imdone Atom: Todays Project Journal` | Alt (⌥ Option)+P | Open todays project journal file |
| `Imdone Atom: Board Zoom In`          | Alt (⌥ Option)+. | Zoom in board                    |
| `Imdone Atom: Board Zoom Out`         | Alt (⌥ Option)+, | Zoom out board                   |
| `Imdone Atom: Export`                 | Alt (⌥ Option)+X | Create `imdone-export.json`      |

Settings
----
| Name                                       | Type    | Default                     | Description                                                                                    |
|:-------------------------------------------|:--------|:----------------------------|:-----------------------------------------------------------------------------------------------|
| Exclude Vcs Ignored Paths                  | boolean | false                       | Exclude files that are ignored by your version control system                                  |
| File Opener Port                           | integer | 9799                        | Port the file opener communicates on                                                           |
| Max Files Prompt                           | integer | 2500                        | How many files is too many to parse without prompting to add ignores?                          |
| Open in Intellij                           | string  | ''                          | [Glob pattern](https://github.com/isaacs/node-glob) for files that should open in Intellij.    |
| Show Notifications                         | boolean | false                       | Show notifications upon clicking task source link.                                             |
| Show Tags Inline                           | boolean | false                       | Display inline tag and context links in task text?                                             |
| Today's Journal Date Format                | string  | YYYY-MM-DD                  | How would you like your `date` variable formatted?                                             |
| Today's Journal Directory                  | string  | $HOME/notes                 | Where do you want your journal files to live? (Their project directory)                        |
| Today's Journal File Name Template         | string  | ${date}.md                  | How do you want your journal files to be named?                                                |
| Today's Journal Project File Name Template | string  | journal/${month}/${date}.md | How do you want your project journal files to be named?                                        |
| Today's Journal Month Format               | string  | YYYY-MM                     | How would you like your `month` variable formatted for use in directory or file name template? |
| Use Alternate File Watcher                 | boolean | false                       | If your board won't update when you edit files, then try the alternate file watcher            |
| Zoom Level                                 | Number  | 1                           | Set the default zoom level on startup.  min: .2, max: 2.5                                      |

License
----

[MIT](LICENSE)
