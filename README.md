The developer's task board
----
**Turn your TODO comments into a task board and let [imdone.io](https://imdone.io) do your issue tracking so you can stay in the zone.**  
Just use `alt+t` while editing a file to see your projects board.

![Static imdone image](https://cloud.githubusercontent.com/assets/233505/20188737/9a3decf8-a73f-11e6-89c3-c3b348c98ae7.png)

[![apm](https://img.shields.io/apm/dm/imdone-atom.svg)](https://atom.io/packages/imdone-atom)
[![apm](https://img.shields.io/apm/v/imdone-atom.svg)]()

You live in the code, your tasks should too!
----
For decades developers have used TODO style code comments to track issues that almost never end up in issue tracking software.  imdone is a plugin for your favorite text editor that turns code comments into trackable issues that you can update from your code.  It collects all TODO style comments in your project and organizes them in a drag and drop task-board that can integrate with [GitHub](https://github.com), [waffle.io](https://waffle.io) and soon [Jira](https://www.atlassian.com/software/jira) using [imdone.io](https://imdone.io).

imdone works best with todo.txt and markdown syntax.  See the [syntax guide at imdone-core](https://github.com/imdone/imdone-core#task-formats) for details.

Features
----
### Filtering your board
imdone uses regular expression matching to filter your cards on your board.
### Using tags in your TODO comments
### Using contexts and @name syntax
### metadata
### Integrate with issue tracking
### Adding and removing tokens
### Code journal
### Using markdown
### Open files in [intellij and webstorm](https://www.jetbrains.com/products.html)
- **Open task links in [intellij](https://www.jetbrains.com/products.html) family of products with imdone-atom and [imdone intellij plugin](https://plugins.jetbrains.com/plugin/8067)!**


Whats new!
----
- Move [waffle.io](https://waffle.io) cards from your code using [imdone.io](https://imdone.io)'s' [github] and [waffle.io](https://waffle.io) integration.
- Open your project readme from the board
- Track Github issues with TODO comments in your code.  Sign up at [imdone.io](https://imdone.io)!


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

Ignoring files
----
- Configuration setting  
You can ignore files with the "Exclude Vcs Ignored Paths" setting

- .imdoneignore  
`.imdoneignore` is implemented using the [ignore](https://www.npmjs.com/package/ignore) package.  Each file in your projects path is tested against the rules in `.imdoneignore`.  
To ignore all but some subdirectories, see this Stack Overflow question. [git - .gitignore exclude folder but include specific subfolder - Stack Overflow](http://stackoverflow.com/questions/5533050/gitignore-exclude-folder-but-include-specific-subfolder)

- .imdone/config.json  
imdone will also ignore files and folders that match a regex in the `.imdone/config.json`, `exclude` array.  The array is seeded with some common excludes on first run.

**IMPORTANT:** If your project is large (#files > 1000) consider adding an .imdoneignore file.
