[![Stories in Ready](https://badge.waffle.io/imdone/imdone-atom.png?label=ready&title=Ready)](https://waffle.io/imdone/imdone-atom)
// A HACK:4 ble task-board in your code.
----
### You live in the code, your tasks should too!

![gifrecord_2015-11-12_085528](https://cloud.githubusercontent.com/assets/233505/11121461/9899fb14-891b-11e5-8aba-a4646f8b1428.gif)

[![apm](https://img.shields.io/apm/dm/imdone-atom.svg)](https://atom.io/packages/imdone-atom)
[![apm](https://img.shields.io/apm/v/imdone-atom.svg)]()

Developers are creative people and the text editor is their canvas.  For decades they've used TODO style code comments to track issues that almost never end up in issue tracking software.  imdone is a plugin for your favorite text editor that turns code comments into trackable issues.  It collects all TODO style comments in your project and organizes them in a drag and drop task-board that integrates with any web based issue tracking system.

imdone works best with todo.txt and markdown syntax.  See the [syntax guide at imdone-core](https://github.com/imdone/imdone-core#task-formats) for details.

Whats new!
----
- :notebook_with_decorative_cover: **Todays's Journal** - Open today's journal file as configured in settings.  Great for people who like to keep plain text notes.
- :zap: **Open all files for filtered tasks!**
- **Open task links in [intellij](https://www.jetbrains.com/products.html) family of products with imdone-atom and [imdone intellij plugin](https://plugins.jetbrains.com/plugin/8067)!**
- **[How To Write Plugins](https://github.com/imdone/imdone-atom/wiki/How-To-Write-Plugins) for imdone-atom**
- **Link your TODO comments to github issues.  Try the [imdone-atom-github](https://atom.io/packages/imdone-atom-github) plugin!**

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

Ignoring files
----
- Configuration setting  
You can ignore files with the "Exclude Vcs Ignored Paths" setting

- .imdoneignore  
[Glob](https://www.npmjs.com/package/glob) patterns in `.imdoneignore` will be matched against files and directories.  For example, if your project is in `/home/jesse/projects/imdone-atom` and your `.imdoneignore` looks like this, then all files and folders in `/home/jesse/projects/imdone-atom/lib` will be ignored.
```
lib
```
- .imdone/config.json  
imdone will also ignore files and folders that match a regex in the `.imdone/config.json`, `exclude` array.  The array is seeded with some common excludes on first run.

**IMPORTANT:** If your project is large (#files > 1000) consider adding an .imdoneignore file.

How To Link Code And Github Issues
----
Using [todo.txt metadata](https://github.com/imdone/imdone-core#metadata) in your tasks and a minor change to `.imdone/config.json`, you can link to external resources like github issues and profiles.  

- Add a `meta` attribute to `.imdone/config.json`  
```javascript
"meta": {
  "issue": {
    "urlTemplate": "https://github.com/imdone/imdone-core/issues/%s",
    "titleTemplate": "github issue #%s"
  }
}
```

- Use `issue:[gh issue id]` as metadata in your tasks.  
<pre>
// &#35;BACKLOG:0 issue:27 Export TODOs
</pre>

- Your issue is linked to the comment!  
![gh-issue-imdone](https://cloud.githubusercontent.com/assets/233505/9595122/72542350-502a-11e5-87b3-a4eb49428b7c.png)

Look at [imdone/imdone-core#metadata](https://github.com/imdone/imdone-core#metadata) for more info.
