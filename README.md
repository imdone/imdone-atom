[![apm](https://img.shields.io/apm/v/imdone-atom.svg)]()
[![apm](https://img.shields.io/apm/dm/imdone-atom.svg)](https://atom.io/packages/imdone-atom)

A task board made from TODO comments in your code and text files
----
Use `alt+t` while editing a file to see your projects board.

imdone-atom recognizes the common TODO style comments we're all used to, with the added flexibility of todo.txt and markdown syntax.  See the [syntax guide at imdone-core](https://github.com/imdone/imdone-core#task-formats) for details.

![Static imdone image](https://cloud.githubusercontent.com/assets/233505/20188737/9a3decf8-a73f-11e6-89c3-c3b348c98ae7.png)

Automate your task flow
----
**Create issues, tasks, stories or anything from TODO comments using [imdone.io](https://imdone.io).**  

**Use the built in GitHub connector or [remix](https://thenextweb.com/apps/2017/03/15/glitch-invites-you-to-remix-other-peoples-code-for-fun-and-functionality/#.tnw_hGWFb3OI) one of these webhooks we've created on [glitch](https://glitch.com) to get started automating the boring stuff.**
- [jira webhook](https://glitch.com/edit/#!/imdone-webhook-jira)
- [trello webhook](https://glitch.com/edit/#!/imdone-webhook-trello)
- [twitter webhook](https://glitch.com/edit/#!/imdone-webhook-twitter)

Getting started with webhooks
----

**Just configure the payloadURL of your [imdone.io](https://imdone.io) project's webhook.  The payloadURL will receive an HTTP POST with the following JSON body.**
```js
{
    "taskNow": {}, // https://github.com/imdone/imdone-core/blob/master/lib/task.js
    "taskBefore": {}, // https://github.com/imdone/imdone-core/blob/master/lib/task.js
    "delta": {} // https://github.com/benjamine/jsondiffpatch/blob/master/docs/deltas.md
}
```

**You can also update tasks by returning a json response in the following format.**
```js
{
  text: "The text of the task id:3 +story tr:19",
  list: "DOING"
}

```

Working webhooks in [Glitch](https://glitch.com)
----
### [imdone-webhook-twitter](https://glitch.com/edit/#!/imdone-webhook-twitter)
- Tweet your TODO comments when they change
- [Check out this blog post to get started](https://medium.com/imdoneio/tweet-from-todo-comments-with-imdone-atom-and-glitch-118e212acac8)  

### [imdone-webhook-trello](https://glitch.com/edit/#!/imdone-webhook-trello)
- Keep your trello board updated using TODO comments

### [imdone-webhook-jira](https://glitch.com/edit/#!/imdone-webhook-jira)
- Keep your team's Jira project updated using TODO comments


You live in the code, your tasks should too!
----
For decades developers have used [TODO style code comments](https://medium.com/imdoneio/5-ways-using-todo-comments-will-make-you-a-better-programmer-240abd00d9e4) to track issues that almost never end up in issue tracking software.  imdone is a plugin for your favorite text editor that turns code comments into trackable issues that you can update from your code.  It collects all TODO style comments in your project and organizes them in a drag and drop task-board that can integrate with [GitHub](https://github.com), [waffle.io](https://waffle.io) and soon whatever you want with webhooks using [imdone.io](https://imdone.io).

Task Board Features
----
### Filtering your board
imdone uses regular expression matching to filter your cards on your board.  The content and the path of the file are searched, but the Token (e.g. TODO) is not searched.
![filter-tasks](https://cloud.githubusercontent.com/assets/233505/21971105/fc44f31c-db72-11e6-857a-17fa92082a46.gif)

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

### Integrate with issue tracking
My favorite feature of imdone are the integrations.  Today you can integrate with github and waffle.io.  Jira SaaS integration is coming soon.


<a href="https://imdone.io/#video" target="_blank"><img src="http://img.youtube.com/vi/ECIfGmngetU/0.jpg" alt="imdone.io integration" width="240" height="180" border="10" /></a>

- Create an issue and attach it to a TODO that has a tag you configure like +enhancement, +feature or +bug

  A TODO like this

  ```js
  // TODO: DRY this code up, and create a new method +enhancement
  ```

  will trun into this

  ```js
  // TODO: DRY this code up, and create a new method +enhancement id:1 gh:1
  ```

  creating github issue number 1 with the title "DRY this code up, and create a new method" and attaching it to the TODO

- Close a TODO's attached issue(s) when it's token changes to something you configure, like DONE.

  A comment like this

  ```js
  // DONE: DRY this code up, and create a new method +enhancement id:1 gh:1
  ```

  would close github issue number 1.

- Comment on a TODO's attached issue(s) when it's modified and optionaly contains a tag you configure

- Create and add labels to a TODO's attached issue(s) for tags that occur in the TODO

  A comment like this

  ```js
  // TODO: DRY this code up, and create a new method +enhancement id:1 gh:1 +groovy
  ```

  would add the label groovy to github issue number 1

-  Move a TODO's attached issues to a waffle.io list you configure when the TODO's token is changed to a token you configure.

  if the token DOING is mapped to "in progress" then a TODO like this

  ```js
  // DOING: DRY this code up, and create a new method +enhancement id:1 gh:1
  ```

  will move the waffle card to the "in progress" list in your waffle.io project

### Adding and removing TODO tokens
You can add a token by just adding an all caps list using the add list button.  If the list name matches this regex `[A-Z]+[A-Z-_]{2,}` a new token will be created.
![Adding a  TODO token](https://cloud.githubusercontent.com/assets/233505/21989108/548c5d9c-dbcf-11e6-96d0-8e2e92e73371.gif)
If the list name matches this this regex `/[\w\-]+?/`, then you will have to use the [hash style syntax](https://github.com/imdone/imdone-core#hash-style) like this...
```js
// #to-do: This is in a list that doesn't have all caps!
```
### Code journal
Configure a directory to use as a daily journal.  Open the daily journal with alt+j.  If your like me, you'll just use dropbox directory for this.  Remember, you can use TODO's in any text file if you put a `#` in front of the token, like this...
```md
This is my simple markdown journal
- #TODO: Finish this work
```

Use your code journal for anything, even planning your next set of features!

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
| Command Palette               | Key Mapping | Description              |
|:------------------------------|:------------|:-------------------------|
| `Imdone Atom: Tasks`          | Alt+T       | Open task board          |
| `Imdone Atom: Todays Journal` | Alt+J       | Open todays journal file |
| `Imdone Atom: Board Zoom In`  | Alt+.       | Zoom in board            |
| `Imdone Atom: Board Zoom Out` | Alt+,       | Zoom out board           |

Settings
----
| Name                               | Type    | Default     | Description                                                                                    |
|:-----------------------------------|:--------|:------------|:-----------------------------------------------------------------------------------------------|
| Exclude Vcs Ignored Paths          | boolean | false       | Exclude files that are ignored by your version control system                                  |
| File Opener Port                   | integer | 9799        | Port the file opener communicates on                                                           |
| Max Files Prompt                   | integer | 2500        | How many files is too many to parse without prompting to add ignores?                          |
| Open in Intellij                   | string  | ''          | [Glob pattern](https://github.com/isaacs/node-glob) for files that should open in Intellij.    |
| Show Notifications                 | boolean | false       | Show notifications upon clicking task source link.                                             |
| Show Tags Inline                   | boolean | false       | Display inline tag and context links in task text?                                             |
| Today's Journal Date Format        | string  | YYYY-MM-DD  | How would you like your `date` variable formatted?                                             |
| Today's Journal Directory          | string  | $HOME/notes | Where do you want your journal files to live? (Their project directory)                        |
| Today's Journal File Name Template | string  | ${date}.md  | How do you want your journal files to be named?                                                |
| Today's Journal Month Format       | string  | YYYY-MM     | How would you like your `month` variable formatted for use in directory or file name template? |
| Use Alternate File Watcher         | boolean | false       | If your board won't update when you edit files, then try the alternate file watcher            |
| Zoom Level                         | Number  | 1           | Set the default zoom level on startup.  min: .2, max: 2.5                                      |
